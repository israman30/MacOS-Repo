import Foundation
import SwiftUI

protocol FileOperationsProtocol {
    func executeActions(_ actions: [CleanupAction]) async -> Bool
    func moveToTrash(_ file: FileInfo) async -> Bool
    func compressKeepingOriginal(_ file: FileInfo) async -> Bool
    func undoLastAction() async -> Bool
}

extension FileOperations: FileOperationsProtocol { }

class FileOperations: ObservableObject {
    @Published var isProcessing = false
    @Published var processingProgress: Double = 0.0
    @Published var currentOperation = ""
    
    private let fileManager = FileManager.default
    private var undoStack: [UndoAction] = []
    private let allowedRootsPolicy = AllowedRootsPolicy()
    
    // MARK: - Undo Action
    struct UndoAction {
        let originalURL: URL
        let newURL: URL
        let action: String
        let timestamp: Date
    }
    
    // MARK: - Execute Cleanup Actions
    func executeActions(_ actions: [CleanupAction]) async -> Bool {
        await MainActor.run {
            isProcessing = true
            processingProgress = 0.0
        }
        
        var successCount = 0
        let totalActions = actions.count
        
        for (index, action) in actions.enumerated() {
            await MainActor.run {
                currentOperation = String(format: ProcessingMessages.processingFile, action.file.name)
                processingProgress = Double(index) / Double(totalActions)
            }
            
            let success = await executeAction(action)
            if success {
                successCount += 1
            }
        }
        
        await MainActor.run {
            isProcessing = false
            processingProgress = 1.0
            currentOperation = ""
        }
        
        return successCount == totalActions
    }
    
    /// Sets the allowed filesystem roots for all destructive operations.
    /// Call this immediately after a user grants folder access.
    func setAllowedRoots(_ roots: [URL]) async {
        await allowedRootsPolicy.setAllowedRoots(roots)
    }
    
    // MARK: - Single-File Helpers (UI actions)
    func moveToTrash(_ file: FileInfo) async -> Bool {
        await performSingleOperation("Moving to Trash: \(file.name)") {
            await self.deleteFile(file)
        }
    }
    
    /// Creates a `.zip` next to the file and keeps the original.
    func compressKeepingOriginal(_ file: FileInfo) async -> Bool {
        await performSingleOperation("Compressing: \(file.name)") {
            await self.compressFileKeepingOriginal(file)
        }
    }
    
    /// Compresses to the destination folder and deletes the original file (space-saving).
    /// `to:` defaults to an empty string to preserve the Swift "default argument" symbol
    /// that Xcode may still reference during incremental builds.
    func compressAndReplace(_ file: FileInfo, to destination: String = "") async -> Bool {
        await performSingleOperation("Compressing: \(file.name)") {
            let finalDestination: String
            if destination.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                finalDestination = file.url
                    .deletingLastPathComponent()
                    .appendingPathComponent("NeatOS Compressed")
                    .path
            } else {
                finalDestination = destination
            }
            
            return await self.compressFile(file, to: finalDestination)
        }
    }
    
    private func performSingleOperation(_ operationName: String, operation: @escaping () async -> Bool) async -> Bool {
        await MainActor.run {
            isProcessing = true
            processingProgress = 0.0
            currentOperation = operationName
        }
        
        let success = await operation()
        
        await MainActor.run {
            isProcessing = false
            processingProgress = 1.0
            currentOperation = ""
        }
        
        return success
    }
    
    // MARK: - Execute Single Action
    private func executeAction(_ action: CleanupAction) async -> Bool {
        switch action.action {
        case .move:
            return await moveFile(action.file, to: action.destination, directDestination: action.moveDirectly)
        case .archive:
            return await archiveFile(action.file, to: action.destination)
        case .delete:
            return await deleteFile(action.file)
        case .compress:
            return await compressFile(action.file, to: action.destination)
        }
    }
    
    // MARK: - Move File
    private func moveFile(_ file: FileInfo, to destination: String, directDestination: Bool = false) async -> Bool {
        do {
            try await allowedRootsPolicy.validateFileIsWithinAllowedRoots(file.url)
            let destinationURL = expandPath(destination)
            let destinationFolder = directDestination ? destinationURL : destinationURL.appendingPathComponent(file.category.rawValue)
            try await allowedRootsPolicy.validateDestinationIsWithinAllowedRoots(destinationFolder)
            
            // Create destination folder if it doesn't exist
            try fileManager.createDirectory(at: destinationFolder, withIntermediateDirectories: true)
            
            let newURL = destinationFolder.appendingPathComponent(file.name)
            
            // Handle filename conflicts
            let finalURL = await resolveFilenameConflict(newURL)
            
            try fileManager.moveItem(at: file.url, to: finalURL)
            
            // Add to undo stack
            let undoAction = UndoAction(
                originalURL: finalURL,
                newURL: file.url,
                action: ActionTypes.move,
                timestamp: Date()
            )
            undoStack.append(undoAction)
            
            return true
        } catch {
            AppLog.fileOps.error("Move failed.")
            return false
        }
    }
    
    // MARK: - Archive File
    private func archiveFile(_ file: FileInfo, to destination: String) async -> Bool {
        do {
            try await allowedRootsPolicy.validateFileIsWithinAllowedRoots(file.url)
            let archiveURL = expandPath(destination)
            try await allowedRootsPolicy.validateDestinationIsWithinAllowedRoots(archiveURL)
            try fileManager.createDirectory(at: archiveURL, withIntermediateDirectories: true)
            
            let archiveName = String(format: FileNamingPatterns.archiveNamePattern, file.name, formatDate(file.modificationDate))
            let archivePath = archiveURL.appendingPathComponent(archiveName)
            let finalPath = await resolveFilenameConflict(archivePath)
            
            // Create zip archive (single-file)
            let success = await createZipArchive(from: file.url, to: finalPath)
            
            if success {
                // Delete original file
                try fileManager.removeItem(at: file.url)
                
                // Add to undo stack
                let undoAction = UndoAction(
                    originalURL: finalPath,
                    newURL: file.url,
                    action: ActionTypes.archive,
                    timestamp: Date()
                )
                undoStack.append(undoAction)
                
                return true
            }
            
            return false
        } catch {
            AppLog.fileOps.error("Archive failed.")
            return false
        }
    }
    
    // MARK: - Delete File
    private func deleteFile(_ file: FileInfo) async -> Bool {
        do {
            try await allowedRootsPolicy.validateFileIsWithinAllowedRoots(file.url)
            // Move to trash instead of permanent deletion
            let trashURL = try fileManager.url(for: .trashDirectory, in: .userDomainMask, appropriateFor: file.url, create: false)
            let trashFile = trashURL.appendingPathComponent(file.name)
            
            let finalTrashURL = await resolveFilenameConflict(trashFile)
            try fileManager.moveItem(at: file.url, to: finalTrashURL)
            
            // Add to undo stack
            let undoAction = UndoAction(
                originalURL: finalTrashURL,
                newURL: file.url,
                action: ActionTypes.delete,
                timestamp: Date()
            )
            undoStack.append(undoAction)
            
            return true
        } catch {
            AppLog.fileOps.error("Delete failed.")
            return false
        }
    }
    
    // MARK: - Compress File
    private func compressFile(_ file: FileInfo, to destination: String) async -> Bool {
        do {
            try await allowedRootsPolicy.validateFileIsWithinAllowedRoots(file.url)
            let compressURL = expandPath(destination)
            try await allowedRootsPolicy.validateDestinationIsWithinAllowedRoots(compressURL)
            try fileManager.createDirectory(at: compressURL, withIntermediateDirectories: true)
            
            let compressedName = String(format: FileNamingPatterns.compressedNamePattern, file.name)
            let compressedPath = compressURL.appendingPathComponent(compressedName)
            
            let finalPath = await resolveFilenameConflict(compressedPath)
            
            // Create zip archive
            let success = await createZipArchive(from: file.url, to: finalPath)
            
            if success {
                // Delete original file
                try fileManager.removeItem(at: file.url)
                
                // Add to undo stack
                let undoAction = UndoAction(
                    originalURL: finalPath,
                    newURL: file.url,
                    action: ActionTypes.compress,
                    timestamp: Date()
                )
                undoStack.append(undoAction)
                
                return true
            }
            
            return false
        } catch {
            AppLog.fileOps.error("Compress failed.")
            return false
        }
    }
    
    private func compressFileKeepingOriginal(_ file: FileInfo) async -> Bool {
        do {
            try await allowedRootsPolicy.validateFileIsWithinAllowedRoots(file.url)
        } catch {
            AppLog.fileOps.error("Compress-copy validation failed.")
            return false
        }
        let folder = file.url.deletingLastPathComponent()
        let compressedName = String(format: FileNamingPatterns.compressedNamePattern, file.name)
        let target = folder.appendingPathComponent(compressedName)
        let finalTarget = await resolveFilenameConflict(target)
        
        let success = await createZipArchive(from: file.url, to: finalTarget)
        guard success else { return false }
        
        // Undo should remove the generated zip (original stays untouched).
        let undoAction = UndoAction(
            originalURL: finalTarget,
            newURL: file.url,
            action: ActionTypes.compressCopy,
            timestamp: Date()
        )
        undoStack.append(undoAction)
        
        return true
    }
    
    // MARK: - Create Zip Archive
    private func createZipArchive(from source: URL, to destination: URL) async -> Bool {
        do {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: SystemPaths.zipExecutable)
            process.currentDirectoryURL = source.deletingLastPathComponent()
            
            if source.hasDirectoryPath {
                // Archive a directory
                process.arguments = ["-r", destination.path, "--", source.lastPathComponent]
                try process.run()
                process.waitUntilExit()
                
                return process.terminationStatus == 0
            } else {
                // Archive a single file
                process.arguments = [destination.path, "--", source.lastPathComponent]
                try process.run()
                process.waitUntilExit()
                
                return process.terminationStatus == 0
            }
        } catch {
            AppLog.fileOps.error("Zip creation failed.")
            return false
        }
    }
    
    // MARK: - Resolve Filename Conflicts
    private func resolveFilenameConflict(_ url: URL) async -> URL {
        var finalURL = url
        var counter = 1
        
        while fileManager.fileExists(atPath: finalURL.path) {
            let name = url.deletingPathExtension().lastPathComponent
            let ext = url.pathExtension
            let newName = ext.isEmpty ? String(format: FileNamingPatterns.duplicatePattern, name, counter) : String(format: FileNamingPatterns.duplicateWithExtensionPattern, name, counter, ext)
            finalURL = url.deletingLastPathComponent().appendingPathComponent(newName)
            counter += 1
        }
        
        return finalURL
    }
    
    // MARK: - Expand Path
    private func expandPath(_ path: String) -> URL {
        let expandedPath = (path as NSString).expandingTildeInPath
        return URL(fileURLWithPath: expandedPath)
    }
    
    // MARK: - Format Date
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = DateFormats.yyyyMMdd
        return formatter.string(from: date)
    }
    
    // MARK: - Undo Last Action
    func undoLastAction() async -> Bool {
        guard let lastAction = undoStack.popLast() else {
            return false
        }
        
        do {
            switch lastAction.action {
            case ActionTypes.move:
                try await allowedRootsPolicy.validateDestinationIsWithinAllowedRoots(lastAction.newURL.deletingLastPathComponent())
                try fileManager.moveItem(at: lastAction.originalURL, to: lastAction.newURL)
            case ActionTypes.archive:
                // Extract from archive and restore
                try await allowedRootsPolicy.validateDestinationIsWithinAllowedRoots(lastAction.newURL.deletingLastPathComponent())
                try await extractAndRestore(from: lastAction.originalURL, to: lastAction.newURL)
            case ActionTypes.delete:
                try await allowedRootsPolicy.validateDestinationIsWithinAllowedRoots(lastAction.newURL.deletingLastPathComponent())
                try fileManager.moveItem(at: lastAction.originalURL, to: lastAction.newURL)
            case ActionTypes.compress:
                try await allowedRootsPolicy.validateDestinationIsWithinAllowedRoots(lastAction.newURL.deletingLastPathComponent())
                try await extractAndRestore(from: lastAction.originalURL, to: lastAction.newURL)
            case ActionTypes.compressCopy:
                try fileManager.removeItem(at: lastAction.originalURL)
            default:
                return false
            }
            
            return true
        } catch {
            AppLog.fileOps.error("Undo failed.")
            return false
        }
    }
    
    // MARK: - Extract and Restore
    private func extractAndRestore(from archiveURL: URL, to originalURL: URL) async throws {
        let tempDir = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        // Extract archive
        let process = Process()
        process.executableURL = URL(fileURLWithPath: SystemPaths.unzipExecutable)
        process.arguments = ["-d", tempDir.path, "--", archiveURL.path]
        
        try process.run()
        process.waitUntilExit()
        
        if process.terminationStatus == 0 {
            // Find the extracted file (zip may contain a folder wrapper)
            if let extracted = try findFirstRegularFileOrFolder(in: tempDir) {
                try fileManager.createDirectory(at: originalURL.deletingLastPathComponent(), withIntermediateDirectories: true)
                if fileManager.fileExists(atPath: originalURL.path) {
                    try fileManager.removeItem(at: originalURL)
                }
                try fileManager.moveItem(at: extracted, to: originalURL)
                // Remove the archive after successful undo (restores pre-action state)
                try? fileManager.removeItem(at: archiveURL)
            }
        }
        
        // Clean up temp directory
        try? fileManager.removeItem(at: tempDir)
    }
    
    private func findFirstRegularFileOrFolder(in directory: URL) throws -> URL? {
        let contents = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles])
        for item in contents {
            let values = try item.resourceValues(forKeys: [.isDirectoryKey])
            if values.isDirectory == true {
                // If it's a directory, prefer a file inside it; otherwise return the folder.
                if let inner = try findFirstRegularFileOrFolder(in: item) {
                    return inner
                }
                return item
            } else {
                return item
            }
        }
        return nil
    }
    
    // MARK: - Get Undo Stack Count
    var canUndo: Bool {
        !undoStack.isEmpty
    }
    
    var undoCount: Int {
        undoStack.count
    }
} 
