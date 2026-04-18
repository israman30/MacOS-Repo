import Foundation
import CryptoKit
import Vision
import AppKit

class FileScanner: ObservableObject {
    @Published var isScanning = false
    @Published var scanProgress: Double = 0.0
    @Published var currentScanLocation = ""
    @Published var lastScanErrorMessage: String?
    
    // MARK: - File Extensions Mapping
    private let imageExtensions = Set(FileExtensions.imageExtensions)
    private let documentExtensions = Set(FileExtensions.documentExtensions)
    private let videoExtensions = Set(FileExtensions.videoExtensions)
    private let audioExtensions = Set(FileExtensions.audioExtensions)
    private let archiveExtensions = Set(FileExtensions.archiveExtensions)
    
    // MARK: - Scan Directories
    func scanDirectories(_ directories: [URL]) async -> ScanResults {
        let locationName = directories.first?.lastPathComponent ?? ""
        let engineInput = ScanEngine.Input(
            imageExtensions: imageExtensions,
            documentExtensions: documentExtensions,
            videoExtensions: videoExtensions,
            audioExtensions: audioExtensions,
            archiveExtensions: archiveExtensions
        )
        
        await MainActor.run {
            lastScanErrorMessage = nil
            isScanning = true
            scanProgress = 0.0
            currentScanLocation = locationName
        }
        
        // Run the heavy scan/analyze work off the MainActor so the UI stays responsive.
        let output = await Task.detached(priority: .userInitiated) { @Sendable in
            let engine = ScanEngine(input: engineInput)
            return engine.scan(directories: directories)
        }.value
        
        await MainActor.run {
            lastScanErrorMessage = output.errorMessage
            isScanning = false
            scanProgress = 1.0
            currentScanLocation = ""
        }
        
        return output.results
    }
}

// MARK: - Scan engine (runs off MainActor)
private struct ScanOutput: Sendable {
    let results: ScanResults
    let errorMessage: String?
}

private struct ScanEngine: Sendable {
    struct Input: Sendable {
        let imageExtensions: Set<String>
        let documentExtensions: Set<String>
        let videoExtensions: Set<String>
        let audioExtensions: Set<String>
        let archiveExtensions: Set<String>
    }
    
    let input: Input
    
    func scan(directories: [URL]) -> ScanOutput {
        var allFiles: [FileInfo] = []
        var firstError: String?
        
        for directory in directories {
            let (files, error) = scanDirectory(directory)
            allFiles.append(contentsOf: files)
            if firstError == nil, let error {
                firstError = error
            }
        }
        
        let categorizedFiles = categorizeFiles(allFiles)
        let duplicates = findDuplicates(allFiles)
        let similarFiles = findSimilarFiles(allFiles, excludingDuplicates: duplicates)
        let oldFiles = allFiles.filter { $0.isOld }
        let largeFiles = allFiles.filter { $0.isLarge }
        let suggestedActions = generateSuggestedActions(
            allFiles,
            duplicates: duplicates,
            similarFiles: similarFiles,
            scannedDirectories: directories
        )
        
        return ScanOutput(
            results: ScanResults(
                totalFiles: allFiles.count,
                filesByCategory: categorizedFiles,
                duplicates: duplicates,
                similarFiles: similarFiles,
                oldFiles: oldFiles,
                largeFiles: largeFiles,
                suggestedActions: suggestedActions
            ),
            errorMessage: firstError
        )
    }
    
    private func scanDirectory(_ directory: URL) -> ([FileInfo], String?) {
        let fileManager = FileManager.default
        let keys: Set<URLResourceKey> = [
            .isDirectoryKey,
            .isRegularFileKey,
            .isSymbolicLinkKey,
            .fileSizeKey,
            .creationDateKey,
            .contentModificationDateKey
        ]
        
        guard let enumerator = fileManager.enumerator(
            at: directory,
            includingPropertiesForKeys: Array(keys),
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else {
            return ([], "I couldn’t scan “\(directory.lastPathComponent)” because macOS didn’t allow the app to enumerate that folder. Try scanning again and when prompted, re-select your \(directory.lastPathComponent) folder.")
        }
        
        var files: [FileInfo] = []
        let skipDirectoryNames: Set<String> = [
            // Developer/build folders that can contain tens/hundreds of thousands of files
            "node_modules", "pods", "carthage", ".git", ".svn", ".hg",
            "deriveddata", ".build", "build", "dist",
            // Common cache folders
            ".cache", ".swiftpm"
        ]
        
        // Use `nextObject()` instead of `Sequence` iteration to avoid Swift 6 async-context
        // restrictions around `makeIterator` on ObjC-backed enumerators.
        while let fileURL = enumerator.nextObject() as? URL {
            do {
                let values = try fileURL.resourceValues(forKeys: keys)
                if values.isSymbolicLink == true {
                    // Avoid unexpected cycles / traversing outside the chosen folder.
                    continue
                }
                
                if values.isDirectory == true {
                    let name = fileURL.lastPathComponent.lowercased()
                    if skipDirectoryNames.contains(name) {
                        enumerator.skipDescendants()
                    }
                    continue
                }
                if values.isRegularFile == false { continue }
                
                let size: Int64 = {
                    if let fileSize = values.fileSize {
                        return Int64(fileSize)
                    }
                    if let attrs = try? fileManager.attributesOfItem(atPath: fileURL.path),
                       let n = attrs[.size] as? NSNumber {
                        return n.int64Value
                    }
                    return 0
                }()
                
                let creationDate = values.creationDate ?? values.contentModificationDate ?? Date()
                let modificationDate = values.contentModificationDate ?? creationDate
                
                let fileExtension = fileURL.pathExtension.lowercased()
                let category = determineCategory(fileExtension, url: fileURL)
                
                files.append(FileInfo(
                    url: fileURL,
                    name: fileURL.lastPathComponent,
                    size: size,
                    creationDate: creationDate,
                    modificationDate: modificationDate,
                    category: category,
                    extension: fileExtension,
                    isDuplicate: false,
                    duplicateGroup: nil
                ))
            } catch {
                // Continue scanning; per-file errors are expected in sandboxed contexts.
                continue
            }
        }
        
        return (files, nil)
    }
    
    private func categorizeFiles(_ files: [FileInfo]) -> [FileCategory: [FileInfo]] {
        var categorized: [FileCategory: [FileInfo]] = [:]
        
        for category in FileCategory.allCases {
            categorized[category] = []
        }
        
        for file in files {
            categorized[file.category, default: []].append(file)
        }
        
        return categorized
    }
    
    private func determineCategory(_ fileExtension: String, url: URL) -> FileCategory {
        if isScreenshot(url) {
            return .screenshots
        }
        
        if input.imageExtensions.contains(fileExtension) {
            return .images
        } else if input.documentExtensions.contains(fileExtension) {
            return .documents
        } else if input.videoExtensions.contains(fileExtension) {
            return .videos
        } else if input.audioExtensions.contains(fileExtension) {
            return .audio
        } else if input.archiveExtensions.contains(fileExtension) {
            return .archives
        }
        
        return .unknown
    }
    
    private func isScreenshot(_ url: URL) -> Bool {
        let name = url.lastPathComponent.lowercased()
        return ScreenshotPatterns.screenshotKeywords.contains { name.contains($0) } ||
               ScreenshotPatterns.imagePrefixes.contains { name.hasPrefix($0) }
    }
    
    private func findDuplicates(_ files: [FileInfo]) -> [String: [FileInfo]] {
        // Fast pre-group by size so we only hash candidates.
        let bySize = Dictionary(grouping: files, by: { $0.size })
        var duplicates: [String: [FileInfo]] = [:]
        
        for (size, group) in bySize where size > 0 && group.count > 1 {
            // Two-stage hashing:
            // - Fast fingerprint (small reads) to narrow candidates
            // - Full SHA256 only for fingerprint collisions to confirm exact duplicates
            var byFingerprint: [String: [FileInfo]] = [:]
            for file in group {
                guard let fp = fileFingerprintHex(url: file.url, sizeBytes: UInt64(size)) else { continue }
                byFingerprint[fp.value, default: []].append(file)
            }
            
            for (_, candidates) in byFingerprint where candidates.count > 1 {
                var byFull: [String: [FileInfo]] = [:]
                for file in candidates {
                    guard let full = fullSHA256Hex(file.url) else { continue }
                    byFull[full, default: []].append(file)
                }
                for (fullHash, hashedGroup) in byFull where hashedGroup.count > 1 {
                    duplicates[fullHash] = hashedGroup
                }
            }
        }
        
        return duplicates
    }
    
    private func findSimilarFiles(_ files: [FileInfo], excludingDuplicates duplicates: [String: [FileInfo]]) -> [[FileInfo]] {
        var similarGroups: [[FileInfo]] = []
        var processed = Set<URL>()
        let duplicateURLs = Set(duplicates.values.flatMap { $0 }.map { $0.url })
        
        // 1) Similar documents: same base name, different versions.
        let documents = files.filter {
            input.documentExtensions.contains($0.extension) && !duplicateURLs.contains($0.url)
        }
        for group in groupByBaseName(documents) where group.count > 1 {
            let sorted = group.sorted { $0.modificationDate > $1.modificationDate }
            if let newest = sorted.first, !processed.contains(newest.url) {
                similarGroups.append(sorted)
                for f in sorted { processed.insert(f.url) }
            }
        }
        
        // 2) Similar images: perceptual similarity via Vision framework.
        let images = files.filter {
            input.imageExtensions.contains($0.extension) && !duplicateURLs.contains($0.url)
        }
        
        // Prevent O(n^2) blowups on large folders.
        guard images.count <= 200 else {
            return similarGroups
        }
        
        for (i, img1) in images.enumerated() where !processed.contains(img1.url) {
            var group = [img1]
            processed.insert(img1.url)
            if i + 1 < images.count {
                for img2 in images[(i + 1)...] where !processed.contains(img2.url) {
                    if areSimilarImages(img1, img2) {
                        group.append(img2)
                        processed.insert(img2.url)
                    }
                }
            }
            if group.count > 1 {
                similarGroups.append(group.sorted { $0.modificationDate > $1.modificationDate })
            }
        }
        
        return similarGroups
    }
    
    private func groupByBaseName(_ files: [FileInfo]) -> [[FileInfo]] {
        var groups: [String: [FileInfo]] = [:]
        for file in files {
            let base = file.url.deletingPathExtension().lastPathComponent
                .lowercased()
                .replacingOccurrences(of: #"[-_\s]*(v\d+|copy|final|draft|old|new)$"#, with: "", options: .regularExpression)
            let key = base.trimmingCharacters(in: .whitespaces)
            if !key.isEmpty {
                groups[key, default: []].append(file)
            }
        }
        return Array(groups.values).filter { $0.count > 1 }
    }
    
    private func areSimilarImages(_ a: FileInfo, _ b: FileInfo) -> Bool {
        let sizeRatio = Double(min(a.size, b.size)) / Double(max(a.size, b.size))
        guard sizeRatio > 0.8 else { return false }
        
        guard let data1 = try? Data(contentsOf: a.url, options: .mappedIfSafe),
              let data2 = try? Data(contentsOf: b.url, options: .mappedIfSafe),
              let img1 = NSImage(data: data1),
              let img2 = NSImage(data: data2),
              let cgImg1 = img1.cgImage(forProposedRect: nil, context: nil, hints: nil),
              let cgImg2 = img2.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return sizeRatio > 0.95
        }
        
        let req1 = VNGenerateImageFeaturePrintRequest()
        let req2 = VNGenerateImageFeaturePrintRequest()
        let handler1 = VNImageRequestHandler(cgImage: cgImg1, options: [:])
        let handler2 = VNImageRequestHandler(cgImage: cgImg2, options: [:])
        
        do {
            try handler1.perform([req1])
            try handler2.perform([req2])
            guard let fp1 = req1.results?.first as? VNFeaturePrintObservation,
                  let fp2 = req2.results?.first as? VNFeaturePrintObservation else {
                return sizeRatio > 0.95
            }
            var distance: Float = 1
            try fp1.computeDistance(&distance, to: fp2)
            return distance < 0.5
        } catch {
            return sizeRatio > 0.95
        }
    }
    
    private struct Fingerprint: Sendable {
        let value: String
    }
    
    private func fileFingerprintHex(url: URL, sizeBytes: UInt64) -> Fingerprint? {
        // For small files, a full hash is fast enough and avoids a second pass.
        let smallFileThreshold: UInt64 = 2 * 1024 * 1024 // 2 MB
        if sizeBytes > 0, sizeBytes <= smallFileThreshold {
            guard let full = fullSHA256Hex(url) else { return nil }
            return Fingerprint(value: full)
        }
        
        let chunkSize = 64 * 1024 // 64 KB
        do {
            let handle = try FileHandle(forReadingFrom: url)
            defer { try? handle.close() }
            
            var hasher = SHA256()
            var sizeLE = sizeBytes.littleEndian
            withUnsafeBytes(of: &sizeLE) { raw in
                hasher.update(data: Data(raw))
            }
            
            // First chunk
            let first = try handle.read(upToCount: chunkSize) ?? Data()
            if first.isEmpty {
                return nil
            }
            hasher.update(data: first)
            
            // Middle chunk
            if sizeBytes > UInt64(chunkSize) {
                let midOffset = sizeBytes / 2
                try handle.seek(toOffset: midOffset)
                let mid = try handle.read(upToCount: chunkSize) ?? Data()
                if !mid.isEmpty {
                    hasher.update(data: mid)
                }
            }
            
            // Last chunk
            if sizeBytes > UInt64(chunkSize) {
                let endOffset = sizeBytes > UInt64(chunkSize) ? (sizeBytes - UInt64(chunkSize)) : 0
                try handle.seek(toOffset: endOffset)
                let last = try handle.read(upToCount: chunkSize) ?? Data()
                if !last.isEmpty {
                    hasher.update(data: last)
                }
            }
            
            let digest = hasher.finalize()
            return Fingerprint(value: digest.map { String(format: HashFormat.hexFormat, $0) }.joined())
        } catch {
            return nil
        }
    }
    
    private func fullSHA256Hex(_ url: URL) -> String? {
        do {
            let handle = try FileHandle(forReadingFrom: url)
            defer { try? handle.close() }
            
            var hasher = SHA256()
            while true {
                let chunk = try handle.read(upToCount: 1024 * 1024) ?? Data()
                if chunk.isEmpty { break }
                hasher.update(data: chunk)
            }
            
            let digest = hasher.finalize()
            return digest.map { String(format: HashFormat.hexFormat, $0) }.joined()
        } catch {
            return nil
        }
    }
    
    private func generateSuggestedActions(_ files: [FileInfo], duplicates: [String: [FileInfo]], similarFiles: [[FileInfo]], scannedDirectories: [URL]) -> [CleanupAction] {
        var actions: [CleanupAction] = []
        let fileManager = FileManager.default
        let downloadsURL = fileManager.urls(for: .downloadsDirectory, in: .userDomainMask).first
        let hoursThreshold = Double(DownloadsAutoSort.hoursThreshold) * 3600
        
        // Smart Tidy: Auto-Sort Downloads (files sitting 24+ hours)
        if let downloads = downloadsURL {
            for file in files {
                guard file.url.path.hasPrefix(downloads.path),
                      let folder = DownloadsAutoSort.extensionToFolder[file.extension.lowercased()] else { continue }
                let hoursSinceCreation = Date().timeIntervalSince(file.creationDate)
                guard hoursSinceCreation >= hoursThreshold else { continue }
                // Sandbox-safe: keep organization inside Downloads (no writing to arbitrary ~/ paths).
                let dest = downloads.appendingPathComponent(folder).path
                actions.append(CleanupAction(
                    file: file,
                    action: .move,
                    destination: dest,
                    description: String(format: ActionDescriptions.autoSortDownload, "Downloads", folder),
                    moveDirectly: true
                ))
            }
        }
        
        // Archive old files
        for file in files where file.isOld {
            // Sandbox-safe: archive beside the file (within the user-granted folder scope).
            let year = Calendar.current.component(.year, from: Date())
            let month = Calendar.current.component(.month, from: Date())
            let yearMonth = String(format: "%d-%02d", year, month)
            let archiveFolder = file.url
                .deletingLastPathComponent()
                .appendingPathComponent("NeatOS Archive")
                .appendingPathComponent(yearMonth)
            actions.append(CleanupAction(
                file: file,
                action: .archive,
                destination: archiveFolder.path,
                description: String(format: ActionDescriptions.archiveOldFile, file.daysSinceModified)
            ))
        }
        
        // Exact duplicates (keep newest, delete the rest)
        for (_, duplicateGroup) in duplicates {
            let sortedDuplicates = duplicateGroup.sorted { $0.modificationDate > $1.modificationDate }
            for duplicate in sortedDuplicates.dropFirst() {
                actions.append(CleanupAction(
                    file: duplicate,
                    action: .delete,
                    destination: SystemPaths.trashPath,
                    description: ActionDescriptions.deleteDuplicate
                ))
            }
        }
        
        // Similar files (keep newest, delete the rest)
        for group in similarFiles {
            let sorted = group.sorted { $0.modificationDate > $1.modificationDate }
            for similar in sorted.dropFirst() {
                actions.append(CleanupAction(
                    file: similar,
                    action: .delete,
                    destination: SystemPaths.trashPath,
                    description: ActionDescriptions.deleteSimilar
                ))
            }
        }
        
        // Compress large files
        for file in files where file.isLarge {
            let compressedFolder = file.url
                .deletingLastPathComponent()
                .appendingPathComponent("NeatOS Compressed")
            actions.append(CleanupAction(
                file: file,
                action: .compress,
                destination: compressedFolder.path,
                description: "Compress large \(file.largeFileTypeSingularLabel.lowercased()) (\(file.formattedSize))"
            ))
        }
        
        return actions
    }
}

// MARK: - URL Extension
extension URL {
    var fileSize: Int64 {
        do {
            let resourceValues = try self.resourceValues(forKeys: [.fileSizeKey])
            return Int64(resourceValues.fileSize ?? 0)
        } catch {
            return 0
        }
    }
} 
