//
//  XcodeCleaner.swift
//  Pepe Assiant
//
//  Xcode Cleaner: Clear Derived Data to reclaim disk space—a massive space-saver for developers.
//

import Foundation
import AppKit

/// Clears Xcode Derived Data to reclaim disk space.
/// Uses NSOpenPanel for sandbox compatibility—user selects the DerivedData folder.
@MainActor
final class XcodeCleaner: ObservableObject {
    
    @Published var isClearing = false
    @Published var lastClearedBytes: Int64?
    @Published var lastError: AppError?
    
    private let fileManager = FileManager.default
    private let byteFormatter: ByteCountFormatter = {
        let f = ByteCountFormatter()
        f.countStyle = .file
        return f
    }()
    
    /// Standard Xcode Derived Data path (for display/guidance).
    /// Uses real user home so the path is correct even when app is sandboxed.
    static var derivedDataPath: String {
        XcodeCleanerText.path
    }
    
    /// Prompts user to select DerivedData folder, then clears its contents.
    /// Returns bytes freed, or nil on cancel/failure.
    func clearDerivedData() async -> Int64? {
        guard !isClearing else { return nil }
        isClearing = true
        lastError = nil
        lastClearedBytes = nil
        
        defer { isClearing = false }
        
        let panel = NSOpenPanel()
        panel.title = XcodeCleanerText.panelTitle
        panel.message = XcodeCleanerText.panelMessage(path: Self.derivedDataPath)
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = false
        
        // Try to open at DerivedData if accessible (may not work in sandbox)
        let derivedDataURL = URL(fileURLWithPath: Self.derivedDataPath)
        if fileManager.fileExists(atPath: Self.derivedDataPath) {
            panel.directoryURL = derivedDataURL
        }
        
        let response = panel.runModal()
        guard response == .OK, let selectedURL = panel.url else {
            return nil
        }
        
        // Security-scoped access for sandbox
        guard selectedURL.startAccessingSecurityScopedResource() else {
            lastError = .permissionDenied(resource: "the selected folder")
            return nil
        }
        defer { selectedURL.stopAccessingSecurityScopedResource() }
        
        let (freed, error) = await deleteContents(of: selectedURL)
        if let err = error {
            lastError = err
            return nil
        }
        lastClearedBytes = freed
        return freed
    }
    
    /// Deletes all contents of the given directory. Returns (bytes freed, error message).
    private func deleteContents(of url: URL) async -> (Int64, AppError?) {
        do {
            let contents = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey], options: [.skipsHiddenFiles])
            var totalFreed: Int64 = 0
            
            for item in contents {
                var size: Int64 = 0
                if let resourceValues = try? item.resourceValues(forKeys: [.fileSizeKey, .isDirectoryKey]) {
                    if resourceValues.isDirectory == true {
                        size = await directorySize(url: item)
                    } else {
                        size = Int64(resourceValues.fileSize ?? 0)
                    }
                }
                
                try fileManager.removeItem(at: item)
                totalFreed += size
            }
            
            return (totalFreed, nil)
        } catch {
            return (0, ErrorHandler.toAppError(error, title: "Could not clear Derived Data"))
        }
    }
    
    private func directorySize(url: URL) async -> Int64 {
        guard let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey], options: [.skipsHiddenFiles]) else { return 0 }
        var total: Int64 = 0
        // Use `nextObject()` instead of `Sequence` iteration to avoid Swift 6 async-context
        // restrictions around `makeIterator` on ObjC-backed enumerators.
        while let fileURL = enumerator.nextObject() as? URL {
            if let size = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                total += Int64(size)
            }
        }
        return total
    }
    
    func formattedBytes(_ bytes: Int64) -> String {
        byteFormatter.string(fromByteCount: bytes)
    }
}
