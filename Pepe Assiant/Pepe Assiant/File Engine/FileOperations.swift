import Foundation
import SwiftUI

class FileOperations: ObservableObject {
    @Published var isProcessing = false
    @Published var processingProgress: Double = 0.0
    @Published var currentOperation = ""
    
    private let fileManager = FileManager.default
    private var undoStack: [UndoAction] = []
    
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
    
    // MARK: - Execute Single Action
    private func executeAction(_ action: CleanupAction) async -> Bool {
        switch action.action {
        case .move:
            return await moveFile(action.file, to: action.destination)
        case .archive:
            return await archiveFile(action.file, to: action.destination)
        case .delete:
            return await deleteFile(action.file)
        case .compress:
            return await compressFile(action.file, to: action.destination)
        }
    }
    
    // MARK: - Move File
    private func moveFile(_ file: FileInfo, to destination: String) async -> Bool {
        do {
            let destinationURL = expandPath(destination)
            let destinationFolder = destinationURL.appendingPathComponent(file.category.rawValue)
            
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
            print(String(format: ErrorMessages.errorMovingFile, error.localizedDescription))
            return false
        }
    }
    
    // MARK: - Archive File
    private func archiveFile(_ file: FileInfo, to destination: String) async -> Bool {
        do {
            let archiveURL = expandPath(destination)
            try fileManager.createDirectory(at: archiveURL, withIntermediateDirectories: true)
            
            let archiveName = String(format: FileNamingPatterns.archiveNamePattern, file.name, formatDate(file.modificationDate))
            let archivePath = archiveURL.appendingPathComponent(archiveName)
            
            // Create a temporary directory for the file
            let tempDir = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)
            
            let tempFile = tempDir.appendingPathComponent(file.name)
            try fileManager.copyItem(at: file.url, to: tempFile)
            
            // Create zip archive
            let success = await createZipArchive(from: tempDir, to: archivePath)
            
            // Clean up temp directory
            try? fileManager.removeItem(at: tempDir)
            
            if success {
                // Delete original file
                try fileManager.removeItem(at: file.url)
                
                // Add to undo stack
                let undoAction = UndoAction(
                    originalURL: file.url,
                    newURL: archivePath,
                    action: ActionTypes.archive,
                    timestamp: Date()
                )
                undoStack.append(undoAction)
                
                return true
            }
            
            return false
        } catch {
            print(String(format: ErrorMessages.errorArchivingFile, error.localizedDescription))
            return false
        }
    }
    
    // MARK: - Delete File
    private func deleteFile(_ file: FileInfo) async -> Bool {
        do {
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
            print(String(format: ErrorMessages.errorDeletingFile, error.localizedDescription))
            return false
        }
    }
    
    // MARK: - Compress File
    private func compressFile(_ file: FileInfo, to destination: String) async -> Bool {
        do {
            let compressURL = expandPath(destination)
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
                    originalURL: file.url,
                    newURL: finalPath,
                    action: ActionTypes.compress,
                    timestamp: Date()
                )
                undoStack.append(undoAction)
                
                return true
            }
            
            return false
        } catch {
            print(String(format: ErrorMessages.errorCompressingFile, error.localizedDescription))
            return false
        }
    }
    
    // MARK: - Create Zip Archive
    private func createZipArchive(from source: URL, to destination: URL) async -> Bool {
        // This is a simplified implementation
        // In a real app, you'd use a proper compression library
        do {
            if source.hasDirectoryPath {
                // Archive a directory
                let process = Process()
                process.executableURL = URL(fileURLWithPath: SystemPaths.zipExecutable)
                process.arguments = ["-r", destination.path, source.path]
                
                try process.run()
                process.waitUntilExit()
                
                return process.terminationStatus == 0
            } else {
                // Archive a single file
                let process = Process()
                process.executableURL = URL(fileURLWithPath: SystemPaths.zipExecutable)
                process.arguments = [destination.path, source.path]
                
                try process.run()
                process.waitUntilExit()
                
                return process.terminationStatus == 0
            }
        } catch {
            print(String(format: ErrorMessages.errorCreatingZipArchive, error.localizedDescription))
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
                try fileManager.moveItem(at: lastAction.originalURL, to: lastAction.newURL)
            case ActionTypes.archive:
                // Extract from archive and restore
                try await extractAndRestore(from: lastAction.originalURL, to: lastAction.newURL)
            case ActionTypes.delete:
                try fileManager.moveItem(at: lastAction.originalURL, to: lastAction.newURL)
            case ActionTypes.compress:
                try await extractAndRestore(from: lastAction.originalURL, to: lastAction.newURL)
            default:
                return false
            }
            
            return true
        } catch {
            print(String(format: ErrorMessages.errorUndoingAction, error.localizedDescription))
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
        process.arguments = [archiveURL.path, "-d", tempDir.path]
        
        try process.run()
        process.waitUntilExit()
        
        if process.terminationStatus == 0 {
            // Find the extracted file
            let contents = try fileManager.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: nil)
            if let extractedFile = contents.first {
                try fileManager.moveItem(at: extractedFile, to: originalURL)
            }
        }
        
        // Clean up temp directory
        try? fileManager.removeItem(at: tempDir)
    }
    
    // MARK: - Get Undo Stack Count
    var canUndo: Bool {
        !undoStack.isEmpty
    }
    
    var undoCount: Int {
        undoStack.count
    }
} 