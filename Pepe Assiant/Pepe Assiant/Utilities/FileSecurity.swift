import Foundation

enum FileSecurityError: Error {
    case notAFileURL
    case outsideAllowedRoots
    case symbolicLinkNotAllowed
}

extension URL {
    /// Canonicalizes a local file URL for safe comparisons:
    /// - standardizes path
    /// - resolves symlinks (best-effort)
    var canonicalFileURL: URL {
        let standardized = standardizedFileURL
        guard standardized.isFileURL else { return standardized }
        return standardized.resolvingSymlinksInPath()
    }
}

struct FileSecurity {
    static func isDescendant(_ candidate: URL, ofRoot root: URL) -> Bool {
        let c = candidate.canonicalFileURL
        let r = root.canonicalFileURL
        let cPath = c.path.hasSuffix("/") ? c.path : (c.path + "/")
        let rPath = r.path.hasSuffix("/") ? r.path : (r.path + "/")
        return cPath.hasPrefix(rPath)
    }
    
    static func requireNonSymlink(_ url: URL) throws {
        guard url.isFileURL else { throw FileSecurityError.notAFileURL }
        let values = try url.resourceValues(forKeys: [.isSymbolicLinkKey])
        if values.isSymbolicLink == true {
            throw FileSecurityError.symbolicLinkNotAllowed
        }
    }
}

actor AllowedRootsPolicy {
    private var roots: [URL] = []
    
    func setAllowedRoots(_ roots: [URL]) {
        self.roots = roots.map { $0.canonicalFileURL }
    }
    
    func validateFileIsWithinAllowedRoots(_ url: URL) throws {
        let candidate = url.canonicalFileURL
        try FileSecurity.requireNonSymlink(candidate)
        
        guard !roots.isEmpty else {
            // If we don't know the allowed roots, fail closed.
            throw FileSecurityError.outsideAllowedRoots
        }
        
        for root in roots where FileSecurity.isDescendant(candidate, ofRoot: root) {
            return
        }
        throw FileSecurityError.outsideAllowedRoots
    }
    
    func validateDestinationIsWithinAllowedRoots(_ url: URL) throws {
        let candidate = url.canonicalFileURL
        guard candidate.isFileURL else { throw FileSecurityError.notAFileURL }
        
        // If the destination already exists, reject symlinks to avoid escaping the allowed root.
        if FileManager.default.fileExists(atPath: candidate.path) {
            try FileSecurity.requireNonSymlink(candidate)
        }
        
        guard !roots.isEmpty else { throw FileSecurityError.outsideAllowedRoots }
        for root in roots where FileSecurity.isDescendant(candidate, ofRoot: root) {
            return
        }
        throw FileSecurityError.outsideAllowedRoots
    }
}

