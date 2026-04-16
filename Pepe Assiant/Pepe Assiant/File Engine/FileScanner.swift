import Foundation
import CryptoKit
import Vision
import AppKit

class FileScanner: ObservableObject {
    @Published var isScanning = false
    @Published var scanProgress: Double = 0.0
    @Published var currentScanLocation = ""
    
    private let fileManager = FileManager.default
    
    // MARK: - File Extensions Mapping
    private let imageExtensions = FileExtensions.imageExtensions
    private let documentExtensions = FileExtensions.documentExtensions
    private let videoExtensions = FileExtensions.videoExtensions
    private let audioExtensions = FileExtensions.audioExtensions
    private let archiveExtensions = FileExtensions.archiveExtensions
    
    // MARK: - Scan Directories
    func scanDirectories(_ directories: [URL]) async -> ScanResults {
        await MainActor.run {
            isScanning = true
            scanProgress = 0.0
        }
        
        var allFiles: [FileInfo] = []
        let totalDirectories = directories.count
        
        for (index, directory) in directories.enumerated() {
            await MainActor.run {
                currentScanLocation = directory.lastPathComponent
                scanProgress = Double(index) / Double(totalDirectories)
            }
            
            let files = await scanDirectory(directory)
            allFiles.append(contentsOf: files)
        }
        
        // Analyze files
        let categorizedFiles = categorizeFiles(allFiles)
        let duplicates = findDuplicates(allFiles)
        let similarFiles = findSimilarFiles(allFiles, excludingDuplicates: duplicates)
        let oldFiles = allFiles.filter { $0.isOld }
        let largeFiles = allFiles.filter { $0.isLarge }
        let suggestedActions = generateSuggestedActions(allFiles, duplicates: duplicates, similarFiles: similarFiles, scannedDirectories: directories)
        
        await MainActor.run {
            isScanning = false
            scanProgress = 1.0
            currentScanLocation = ""
        }
        
        return ScanResults(
            totalFiles: allFiles.count,
            filesByCategory: categorizedFiles,
            duplicates: duplicates,
            similarFiles: similarFiles,
            oldFiles: oldFiles,
            largeFiles: largeFiles,
            suggestedActions: suggestedActions
        )
    }
    
    // MARK: - Scan Single Directory
    private func scanDirectory(_ directory: URL) async -> [FileInfo] {
        guard let enumerator = fileManager.enumerator(at: directory, includingPropertiesForKeys: [.fileSizeKey, .creationDateKey, .contentModificationDateKey], options: [.skipsHiddenFiles, .skipsPackageDescendants]) else {
            return []
        }
        
        var files: [FileInfo] = []
        
        // Use `nextObject()` instead of `Sequence` iteration to avoid Swift 6 async-context
        // restrictions around `makeIterator` on ObjC-backed enumerators.
        while let fileURL = enumerator.nextObject() as? URL {
            guard fileURL.hasDirectoryPath == false else { continue }
            
            do {
                let resourceValues = try fileURL.resourceValues(forKeys: [.fileSizeKey, .creationDateKey, .contentModificationDateKey])
                
                guard let size = resourceValues.fileSize,
                      let creationDate = resourceValues.creationDate,
                      let modificationDate = resourceValues.contentModificationDate else {
                    continue
                }
                
                let fileExtension = fileURL.pathExtension.lowercased()
                let category = determineCategory(fileExtension, url: fileURL)
                
                let fileInfo = FileInfo(
                    url: fileURL,
                    name: fileURL.lastPathComponent,
                    size: Int64(size),
                    creationDate: creationDate,
                    modificationDate: modificationDate,
                    category: category,
                    extension: fileExtension,
                    isDuplicate: false,
                    duplicateGroup: nil
                )
                
                files.append(fileInfo)
            } catch {
                print(String(format: ErrorMessages.errorReadingFile, fileURL.path, error.localizedDescription))
            }
        }
        
        return files
    }
    
    // MARK: - Categorize Files
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
    
    // MARK: - Determine File Category
    private func determineCategory(_ fileExtension: String, url: URL) -> FileCategory {
        // Check for screenshots first
        if isScreenshot(url) {
            return .screenshots
        }
        
        // Check other categories
        if imageExtensions.contains(fileExtension) {
            return .images
        } else if documentExtensions.contains(fileExtension) {
            return .documents
        } else if videoExtensions.contains(fileExtension) {
            return .videos
        } else if audioExtensions.contains(fileExtension) {
            return .audio
        } else if archiveExtensions.contains(fileExtension) {
            return .archives
        }
        
        return .unknown
    }
    
    // MARK: - Detect Screenshots
    private func isScreenshot(_ url: URL) -> Bool {
        let name = url.lastPathComponent.lowercased()
        return ScreenshotPatterns.screenshotKeywords.contains { name.contains($0) } || 
               ScreenshotPatterns.imagePrefixes.contains { name.hasPrefix($0) }
    }
    
    // MARK: - Find Duplicates
    private func findDuplicates(_ files: [FileInfo]) -> [String: [FileInfo]] {
        var hashGroups: [String: [FileInfo]] = [:]
        
        for file in files {
            let hash = calculateFileHash(file.url)
            hashGroups[hash, default: []].append(file)
        }
        
        // Filter out groups with only one file (no duplicates)
        return hashGroups.filter { $0.value.count > 1 }
    }
    
    // MARK: - Find Similar Files (Smart Tidy: beyond exact duplicates)
    private func findSimilarFiles(_ files: [FileInfo], excludingDuplicates duplicates: [String: [FileInfo]]) -> [[FileInfo]] {
        var similarGroups: [[FileInfo]] = []
        var processed = Set<URL>()
        let duplicateURLs = Set(duplicates.values.flatMap { $0 }.map { $0.url })
        
        // 1. Similar documents: same base name, different versions (e.g., report.docx, report_v2.pdf)
        let documents = files.filter {
            FileExtensions.documentExtensions.contains($0.extension) && !duplicateURLs.contains($0.url)
        }
        let docGroups = groupByBaseName(documents)
        for group in docGroups where group.count > 1 {
            let sorted = group.sorted { $0.modificationDate > $1.modificationDate }
            if !sorted.isEmpty && !processed.contains(sorted[0].url) {
                similarGroups.append(sorted)
                for f in sorted { processed.insert(f.url) }
            }
        }
        
        // 2. Similar images: perceptual similarity via Vision framework
        let images = files.filter {
            FileExtensions.imageExtensions.contains($0.extension) && !duplicateURLs.contains($0.url)
        }
        for (i, img1) in images.enumerated() where !processed.contains(img1.url) {
            var group = [img1]
            processed.insert(img1.url)
            for img2 in images[(i+1)...] where !processed.contains(img2.url) {
                if areSimilarImages(img1, img2) {
                    group.append(img2)
                    processed.insert(img2.url)
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
        // Similar size (within 20%) as quick filter
        let sizeRatio = Double(min(a.size, b.size)) / Double(max(a.size, b.size))
        guard sizeRatio > 0.8 else { return false }
        
        // Use Vision framework for perceptual similarity when available
        guard let data1 = try? Data(contentsOf: a.url),
              let data2 = try? Data(contentsOf: b.url),
              let img1 = NSImage(data: data1),
              let img2 = NSImage(data: data2),
              let cgImg1 = img1.cgImage(forProposedRect: nil, context: nil, hints: nil),
              let cgImg2 = img2.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return sizeRatio > 0.95  // Fallback: very similar size
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
            return distance < 0.5  // Perceptual similarity threshold
        } catch {
            return sizeRatio > 0.95
        }
    }
    
    // MARK: - Calculate File Hash
    private func calculateFileHash(_ url: URL) -> String {
        do {
            let data = try Data(contentsOf: url)
            let hash = SHA256.hash(data: data)
            return hash.compactMap { String(format: HashFormat.hexFormat, $0) }.joined()
        } catch {
            // Fallback to file name and size for large files
            return String(format: FileNamingPatterns.fileHashPattern, url.lastPathComponent, String(url.fileSize))
        }
    }
    
    // MARK: - Generate Suggested Actions
    private func generateSuggestedActions(_ files: [FileInfo], duplicates: [String: [FileInfo]], similarFiles: [[FileInfo]], scannedDirectories: [URL]) -> [CleanupAction] {
        var actions: [CleanupAction] = []
        let downloadsURL = fileManager.urls(for: .downloadsDirectory, in: .userDomainMask).first
        let hoursThreshold = Double(DownloadsAutoSort.hoursThreshold) * 3600
        
        // Smart Tidy: Auto-Sort Downloads (files sitting 24+ hours)
        if let downloads = downloadsURL {
            for file in files {
                guard file.url.path.hasPrefix(downloads.path),
                      let folder = DownloadsAutoSort.extensionToFolder[file.extension.lowercased()] else { continue }
                let hoursSinceCreation = Date().timeIntervalSince(file.creationDate)
                guard hoursSinceCreation >= hoursThreshold else { continue }
                let dest = "~/\(folder)"
                let action = CleanupAction(
                    file: file,
                    action: .move,
                    destination: dest,
                    description: String(format: ActionDescriptions.autoSortDownload, "Downloads", folder),
                    moveDirectly: true
                )
                actions.append(action)
            }
        }
        
        // Archive old files
        for file in files where file.isOld {
            let action = CleanupAction(
                file: file,
                action: .archive,
                destination: String(format: ArchivePaths.yearMonthPattern, Calendar.current.component(.year, from: Date()), Calendar.current.component(.month, from: Date())),
                description: String(format: ActionDescriptions.archiveOldFile, file.daysSinceModified)
            )
            actions.append(action)
        }
        
        // Handle exact duplicates
        for (_, duplicateGroup) in duplicates {
            let sortedDuplicates = duplicateGroup.sorted { $0.modificationDate > $1.modificationDate }
            for duplicate in sortedDuplicates.dropFirst() {
                let action = CleanupAction(
                    file: duplicate,
                    action: .delete,
                    destination: SystemPaths.trashPath,
                    description: ActionDescriptions.deleteDuplicate
                )
                actions.append(action)
            }
        }
        
        // Smart Tidy: Similar files (keep best, delete others)
        for group in similarFiles {
            let sorted = group.sorted { $0.modificationDate > $1.modificationDate }
            for similar in sorted.dropFirst() {
                let action = CleanupAction(
                    file: similar,
                    action: .delete,
                    destination: SystemPaths.trashPath,
                    description: ActionDescriptions.deleteSimilar
                )
                actions.append(action)
            }
        }
        
        // Compress large files
        for file in files where file.isLarge {
            let action = CleanupAction(
                file: file,
                action: .compress,
                destination: SystemPaths.compressedPath,
                description: "Compress large \(file.largeFileTypeSingularLabel.lowercased()) (\(file.formattedSize))"
            )
            actions.append(action)
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
