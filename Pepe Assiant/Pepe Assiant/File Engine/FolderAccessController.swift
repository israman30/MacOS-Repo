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
    private let keychain = KeychainStore()
    
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
    
    /// The set of folder roots currently held open via security-scoped access.
    /// Use to enforce a least-privilege boundary for file operations.
    var currentAccessibleRoots: [URL] {
        Array(activeSecurityScopedURLs.values)
    }
    
    /// Returns a usable URL for the folder, requesting user permission if needed.
    /// If the user cancels the permission prompt, returns nil.
    func ensureAccess(to folder: KnownFolder) -> URL? {
        if let active = activeSecurityScopedURLs[folder] {
            return active
        }
        
        if let resolved = resolveBookmarkURL(for: folder) {
            if resolved.startAccessingSecurityScopedResource() {
                // Hard boundary: never allow a broader folder than we asked for.
                if validateSelection(resolved, for: folder) {
                    activeSecurityScopedURLs[folder] = resolved
                    return resolved
                } else {
                    resolved.stopAccessingSecurityScopedResource()
                    deleteBookmark(for: folder)
                }
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

        guard validateSelection(userSelected, for: folder) else {
            presentInvalidSelectionAlert(for: folder, expected: suggested)
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
            try keychain.setData(data, forKey: folder.bookmarkDefaultsKey)
        } catch {
            // If we can't save the bookmark, we'll still work for this session.
            AppLog.security.error("Failed to save folder bookmark. folder=\(folder.rawValue, privacy: .public)")
        }
    }
    
    private func resolveBookmarkURL(for folder: KnownFolder) -> URL? {
        let data: Data?
        do {
            if let kc = try keychain.getData(forKey: folder.bookmarkDefaultsKey) {
                data = kc
            } else if let legacy = defaults.data(forKey: folder.bookmarkDefaultsKey) {
                // Migrate legacy storage from UserDefaults → Keychain.
                data = legacy
                try? keychain.setData(legacy, forKey: folder.bookmarkDefaultsKey)
                defaults.removeObject(forKey: folder.bookmarkDefaultsKey)
            } else {
                data = nil
            }
        } catch {
            AppLog.security.error("Failed to read folder bookmark. folder=\(folder.rawValue, privacy: .public)")
            data = nil
        }
        
        guard let data else { return nil }
        
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
            AppLog.security.error("Failed to resolve folder bookmark. folder=\(folder.rawValue, privacy: .public)")
            return nil
        }
    }
    
    private func deleteBookmark(for folder: KnownFolder) {
        defaults.removeObject(forKey: folder.bookmarkDefaultsKey)
        try? keychain.delete(forKey: folder.bookmarkDefaultsKey)
    }
    
    /// Ensures the selected folder does not grant more access than intended.
    private func validateSelection(_ selected: URL, for folder: KnownFolder) -> Bool {
        guard let expected = fileManager.urls(for: folder.searchPathDirectory, in: .userDomainMask).first else {
            return false
        }
        let expectedCanonical = expected.canonicalFileURL
        let selectedCanonical = selected.canonicalFileURL
        
        // Allow exact match (strongest). This avoids users accidentally selecting Home/iCloud Drive.
        if selectedCanonical.path == expectedCanonical.path {
            return true
        }
        
        // Allow narrower selection (subfolder inside the expected folder).
        if FileSecurity.isDescendant(selectedCanonical, ofRoot: expectedCanonical) {
            return true
        }
        
        return false
    }
    
    private func presentInvalidSelectionAlert(for folder: KnownFolder, expected: URL) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Wrong folder selected"
        alert.informativeText = "For security, NeatOS only accepts access to your \(folder.displayName) folder (or a subfolder inside it). Please try again and select “\(expected.lastPathComponent)”."
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
