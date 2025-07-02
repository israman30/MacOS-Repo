import Foundation
import CryptoKit

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
        let oldFiles = allFiles.filter { $0.isOld }
        let largeFiles = allFiles.filter { $0.isLarge }
        let suggestedActions = generateSuggestedActions(allFiles, duplicates: duplicates)
        
        await MainActor.run {
            isScanning = false
            scanProgress = 1.0
            currentScanLocation = ""
        }
        
        return ScanResults(
            totalFiles: allFiles.count,
            filesByCategory: categorizedFiles,
            duplicates: duplicates,
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
        
        for case let fileURL as URL in enumerator {
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
    private func generateSuggestedActions(_ files: [FileInfo], duplicates: [String: [FileInfo]]) -> [CleanupAction] {
        var actions: [CleanupAction] = []
        
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
        
        // Handle duplicates
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
        
        // Compress large files
        for file in files where file.isLarge {
            let action = CleanupAction(
                file: file,
                action: .compress,
                            destination: SystemPaths.compressedPath,
            description: String(format: ActionDescriptions.compressLargeFile, file.formattedSize)
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
