//
//  Constants.swift
//  Pepe Assiant
//
//  Created by Israel Manzo on 7/1/25.
//

import Foundation
import SwiftUI

// MARK: - App Information
struct AppConstants {
    static let appName = "Pepe Assistant"
    static let appDescription = "Your friendly file organization bot"
    static let appTagline = "Hi! I'm Pepe, your file organization assistant. I can help you clean up your desktop, organize downloads, find duplicates, and archive old files. Just tell me what you'd like to do!"
}

// MARK: - UI Text
struct UIText {
    // Navigation
    static let scanResults = "Scan Results"
    static let previewActions = "Preview Actions"
    static let suggestedActions = "Suggested Actions"
    
    // Buttons
    static let done = "Done"
    static let cancel = "Cancel"
    static let selectAll = "Select All"
    static let deselectAll = "Deselect All"
    static let executeSelected = "Execute Selected"
    static let send = "Send"
    static let undo = "Undo"
    
    // Input Fields
    static let messageInputPlaceholder = "Type your request..."
    
    // Headers and Titles
    static let readyToOrganize = "Ready to organize your files"
    static let totalFiles = "Total Files"
    static let totalSize = "Total Size"
    static let duplicates = "Duplicates"
    static let oldFiles = "Old Files"
    static let largeFiles = "Large Files"
    
    // Status Messages
    static let scanning = "Scanning"
    static let processing = "Processing"
    static let actionsSelected = "actions selected"
    static let of = "of"
    
    // Accessibility
    static let pepeAssistantHeader = "Pepe Assistant header with undo button"
    static let scanningProgress = "Scanning progress"
    static let processingProgress = "Processing progress"
    static let messageInputField = "Message input field"
    static let sendMessage = "Send message"
    static let selectAction = "Select action"
    static let deselectAction = "Deselect action"
    static let summary = "Summary"
    static let complete = "complete"
    static let doubleTapToSelect = "Double tap to select this action"
    static let doubleTapToDeselect = "Double tap to deselect this action"
}

// MARK: - Bot Messages
struct BotMessages {
    // Greeting and Help
    static let welcomeMessage = "Hi! I'm Pepe, your file organization assistant. I can help you clean up your desktop, organize downloads, find duplicates, and archive old files. Just tell me what you'd like to do!"
    static let helpMessage = "I can help you organize your files! Try saying 'clean my desktop', 'scan downloads', or 'find duplicates'."
    static let chooseLocationMessage = "I can help clean your desktop, downloads, or documents. Which would you like me to organize?"
    
    // Scan Messages
    static let scanDesktopMessage = "I'll scan your desktop and help organize your files. Let me take a look..."
    static let scanDownloadsMessage = "I'll scan your Downloads folder and help clean it up. Let me check what's there..."
    static let scanDocumentsMessage = "I'll scan your Documents folder and help organize your files. Let me examine what you have..."
    static let scanGeneralMessage = "I'll scan your desktop to see what files we're working with. Let me take a look..."
    
    // Action Messages
    static let duplicateMessage = "I'll scan for duplicate files and help you clean them up. Let me check your desktop first..."
    static let archiveMessage = "I'll look for old files that can be archived. Let me scan your desktop..."
    
    // Results Messages
    static let foundFilesMessage = "I found %d files (%@) on your desktop. "
    static let suggestActionsMessage = "I can suggest %d cleanup actions to organize your files. Would you like to see them?"
    static let alreadyOrganizedMessage = "Everything looks pretty organized already!"
    static let cleanupSuccessMessage = "Great! I've completed the cleanup. Your files are now better organized. You can undo any changes if needed."
    static let cleanupErrorMessage = "I encountered some issues while cleaning up. Some files may not have been processed. You can try again or check the results."
}

// MARK: - File Categories
struct FileCategories {
    static let images = "Images"
    static let documents = "Documents"
    static let videos = "Videos"
    static let audio = "Audio"
    static let archives = "Archives"
    static let screenshots = "Screenshots"
    static let downloads = "Downloads"
    static let unknown = "Unknown"
}

// MARK: - System Icons
struct SystemIcons {
    // General UI
    static let sparkles = "sparkles"
    static let magnifyingglass = "magnifyingglass"
    static let checkmarkCircle = "checkmark.circle"
    static let checkmarkCircleFill = "checkmark.circle.fill"
    static let circle = "circle"
    static let listBullet = "list.bullet"
    static let arrowUpCircleFill = "arrow.up.circle.fill"
    static let arrowRight = "arrow.right"
    
    // File Types
    static let photo = "photo"
    static let docText = "doc.text"
    static let video = "video"
    static let musicNote = "music.note"
    static let archivebox = "archivebox"
    static let camera = "camera"
    static let arrowDownCircle = "arrow.down.circle"
    static let questionmarkCircle = "questionmark.circle"
    static let doc = "doc"
    static let externaldrive = "externaldrive"
    static let docOnDoc = "doc.on.doc"
    static let clock = "clock"
    static let arrowUpCircle = "arrow.up.circle"
    
    // Actions
    static let folder = "folder"
    static let trash = "trash"
    static let zip = "zip"
}

// MARK: - File Extensions
struct FileExtensions {
    static let imageExtensions = ["jpg", "jpeg", "png", "gif", "bmp", "tiff", "webp", "heic", "heif"]
    static let documentExtensions = ["pdf", "doc", "docx", "txt", "rtf", "pages", "key", "numbers", "xls", "xlsx", "ppt", "pptx"]
    static let videoExtensions = ["mp4", "mov", "avi", "mkv", "wmv", "flv", "webm", "m4v"]
    static let audioExtensions = ["mp3", "wav", "aac", "flac", "m4a", "ogg", "wma"]
    static let archiveExtensions = ["zip", "rar", "7z", "tar", "gz", "bz2", "dmg"]
}

// MARK: - System Paths
struct SystemPaths {
    static let zipExecutable = "/usr/bin/zip"
    static let unzipExecutable = "/usr/bin/unzip"
    static let archivePath = "~/Archive"
    static let trashPath = "Trash"
    static let compressedPath = "~/Compressed"
}

// MARK: - Action Types
struct ActionTypes {
    static let move = "move"
    static let archive = "archive"
    static let delete = "delete"
    static let compress = "compress"
}

// MARK: - Action Descriptions
struct ActionDescriptions {
    static let archiveOldFile = "Archive old file (%d days old)"
    static let deleteDuplicate = "Delete duplicate (keep newer version)"
    static let compressLargeFile = "Compress large file (%@)"
}

// MARK: - Date Formats
struct DateFormats {
    static let yyyyMMdd = "yyyy-MM-dd"
}

// MARK: - File Naming Patterns
struct FileNamingPatterns {
    static let duplicatePattern = "%@ (%d)"
    static let duplicateWithExtensionPattern = "%@ (%d).%@"
    static let archiveNamePattern = "%@_%@.zip"
    static let compressedNamePattern = "%@.zip"
    static let fileHashPattern = "%@_%@"
}

// MARK: - Error Messages
struct ErrorMessages {
    static let errorReadingFile = "Error reading file: %@, error: %@"
    static let errorMovingFile = "Error moving file: %@"
    static let errorArchivingFile = "Error archiving file: %@"
    static let errorDeletingFile = "Error deleting file: %@"
    static let errorCompressingFile = "Error compressing file: %@"
    static let errorCreatingZipArchive = "Error creating zip archive: %@"
    static let errorUndoingAction = "Error undoing action: %@"
}

// MARK: - Processing Messages
struct ProcessingMessages {
    static let processingFile = "Processing: %@"
}

// MARK: - Archive Paths
struct ArchivePaths {
    static let yearMonthPattern = "~/Archive/%d-%02d"
}

// MARK: - Screenshot Detection
struct ScreenshotPatterns {
    static let screenshotKeywords = ["screenshot", "screen shot"]
    static let imagePrefixes = ["img_", "photo_"]
}

// MARK: - Hash Format
struct HashFormat {
    static let hexFormat = "%02x"
}

// MARK: - User Input Keywords
struct UserInputKeywords {
    static let clean = "clean"
    static let organize = "organize"
    static let desktop = "desktop"
    static let download = "download"
    static let document = "document"
    static let scan = "scan"
    static let check = "check"
    static let duplicate = "duplicate"
    static let archive = "archive"
    static let old = "old"
}

// MARK: - Action Button Labels
struct ActionButtonLabels {
    static let scanDesktop = "Scan Desktop"
    static let scanDownloads = "Scan Downloads"
    static let scanDocuments = "Scan Documents"
    static let cleanAll = "Clean All"
    static let viewResults = "View Results"
}
