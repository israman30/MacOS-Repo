import Foundation
import SwiftUI

// MARK: - File Types and Categories
enum FileCategory: String, CaseIterable {
    case images = FileCategories.images
    case documents = FileCategories.documents
    case videos = FileCategories.videos
    case audio = FileCategories.audio
    case archives = FileCategories.archives
    case screenshots = FileCategories.screenshots
    case downloads = FileCategories.downloads
    case unknown = FileCategories.unknown
    
    var icon: String {
        switch self {
        case .images: return SystemIcons.photo
        case .documents: return SystemIcons.docText
        case .videos: return SystemIcons.video
        case .audio: return SystemIcons.musicNote
        case .archives: return SystemIcons.archivebox
        case .screenshots: return SystemIcons.camera
        case .downloads: return SystemIcons.arrowDownCircle
        case .unknown: return SystemIcons.questionmarkCircle
        }
    }
    
    var color: Color {
        switch self {
        case .images: return .blue
        case .documents: return .green
        case .videos: return .purple
        case .audio: return .orange
        case .archives: return .gray
        case .screenshots: return .cyan
        case .downloads: return .yellow
        case .unknown: return .red
        }
    }
}

// MARK: - File Information Model
struct FileInfo: Identifiable, Hashable {
    let id = UUID()
    let url: URL
    let name: String
    let size: Int64
    let creationDate: Date
    let modificationDate: Date
    let category: FileCategory
    let `extension`: String
    let isDuplicate: Bool
    let duplicateGroup: String?
    
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
    
    var daysSinceModified: Int {
        Calendar.current.dateComponents([.day], from: modificationDate, to: Date()).day ?? 0
    }
    
    var isOld: Bool {
        daysSinceModified > 90
    }
    
    var isLarge: Bool {
        size > 500 * 1024 * 1024 // 500MB
    }
}

// MARK: - Sorting Rules
struct SortingRule: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let condition: (FileInfo) -> Bool
    let action: (FileInfo) -> String
    let isEnabled: Bool
    
    init(name: String, description: String, condition: @escaping (FileInfo) -> Bool, action: @escaping (FileInfo) -> String, isEnabled: Bool = true) {
        self.name = name
        self.description = description
        self.condition = condition
        self.action = action
        self.isEnabled = isEnabled
    }
}

// MARK: - Cleanup Action
struct CleanupAction: Identifiable {
    let id = UUID()
    let file: FileInfo
    let action: ActionType
    let destination: String
    let description: String
    
    enum ActionType {
        case move
        case archive
        case delete
        case compress
    }
}

// MARK: - Scan Results
struct ScanResults {
    let totalFiles: Int
    let filesByCategory: [FileCategory: [FileInfo]]
    let duplicates: [String: [FileInfo]]
    let oldFiles: [FileInfo]
    let largeFiles: [FileInfo]
    let suggestedActions: [CleanupAction]
    
    var totalSize: Int64 {
        filesByCategory.values.flatMap { $0 }.reduce(0) { $0 + $1.size }
    }
    
    var formattedTotalSize: String {
        ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }
} 
