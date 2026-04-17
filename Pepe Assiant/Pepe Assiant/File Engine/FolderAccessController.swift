import Foundation
import AppKit

@MainActor
final class FolderAccessController: ObservableObject {
    enum KnownFolder: String, CaseIterable, Hashable {
        case desktop
        case downloads
        case documents
        
        var displayName: String {
            switch self {
            case .desktop: return "Desktop"
            case .downloads: return "Downloads"
            case .documents: return "Documents"
            }
        }
        
        var searchPathDirectory: FileManager.SearchPathDirectory {
            switch self {
            case .desktop: return .desktopDirectory
            case .downloads: return .downloadsDirectory
            case .documents: return .documentDirectory
            }
        }
        
        fileprivate var bookmarkDefaultsKey: String {
            "NeatOS.bookmark.\(rawValue)"
        }
    }
    
    private let fileManager = FileManager.default
    private let defaults: UserDefaults
    
    /// Active security-scoped URLs we are currently holding open.
    private var activeSecurityScopedURLs: [KnownFolder: URL] = [:]
    
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }
    
    deinit {
        // Best-effort cleanup. Avoid capturing `self` in an escaping closure (Swift 6 error).
        let urlsToClose = Array(activeSecurityScopedURLs.values)
        Task { @MainActor [urlsToClose] in
            for url in urlsToClose {
                url.stopAccessingSecurityScopedResource()
            }
        }
    }
    
    func stopAllAccess() {
        for (_, url) in activeSecurityScopedURLs {
            url.stopAccessingSecurityScopedResource()
        }
        activeSecurityScopedURLs.removeAll()
    }
    
    /// Returns a usable URL for the folder, requesting user permission if needed.
    /// If the user cancels the permission prompt, returns nil.
    func ensureAccess(to folder: KnownFolder) -> URL? {
        if let active = activeSecurityScopedURLs[folder] {
            return active
        }
        
        if let resolved = resolveBookmarkURL(for: folder) {
            if resolved.startAccessingSecurityScopedResource() {
                activeSecurityScopedURLs[folder] = resolved
                return resolved
            }
        }
        
        guard let suggested = fileManager.urls(for: folder.searchPathDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        guard let userSelected = promptForFolderAccess(
            title: "Allow access to \(folder.displayName)",
            message: "NeatOS needs your permission to scan and organize files in your \(folder.displayName) folder.\n\nPlease select your \(folder.displayName) folder to allow access.",
            suggestedURL: suggested
        ) else {
            return nil
        }
        
        // Persist access for future scans.
        saveBookmark(for: userSelected, folder: folder)
        
        // Prefer using the resolved bookmark URL (handles sandbox security scope).
        let finalURL = resolveBookmarkURL(for: folder) ?? userSelected
        guard finalURL.startAccessingSecurityScopedResource() else {
            return nil
        }
        
        activeSecurityScopedURLs[folder] = finalURL
        return finalURL
    }
    
    private func promptForFolderAccess(title: String, message: String, suggestedURL: URL) -> URL? {
        let panel = NSOpenPanel()
        panel.title = title
        panel.message = message
        panel.prompt = "Allow"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = false
        panel.directoryURL = suggestedURL
        
        let response = panel.runModal()
        guard response == .OK, let url = panel.url else {
            return nil
        }
        return url
    }
    
    private func saveBookmark(for url: URL, folder: KnownFolder) {
        do {
            let data = try url.bookmarkData(
                options: [.withSecurityScope],
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            defaults.set(data, forKey: folder.bookmarkDefaultsKey)
        } catch {
            // If we can't save the bookmark, we'll still work for this session.
            print("Failed to save bookmark for \(folder.displayName): \(error.localizedDescription)")
        }
    }
    
    private func resolveBookmarkURL(for folder: KnownFolder) -> URL? {
        guard let data = defaults.data(forKey: folder.bookmarkDefaultsKey) else {
            return nil
        }
        
        var stale = false
        do {
            let url = try URL(
                resolvingBookmarkData: data,
                options: [.withSecurityScope],
                relativeTo: nil,
                bookmarkDataIsStale: &stale
            )
            
            if stale {
                saveBookmark(for: url, folder: folder)
            }
            
            return url
        } catch {
            print("Failed to resolve bookmark for \(folder.displayName): \(error.localizedDescription)")
            return nil
        }
    }
}
