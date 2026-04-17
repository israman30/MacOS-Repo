//
//  AppViewModel.swift
//  Pepe Assiant
//
//  Created by Israel Manzo on 4/17/26.
//

import SwiftUI

@MainActor
/// App-level state holder and “composition root” for the core engines.
///
/// `BotAssistantView` creates this ViewModel as a `@StateObject` so the same instances
/// of the scanners/operations live for the lifetime of the chat UI. Keeping this type
/// `@MainActor` ensures SwiftUI reads/writes happen on the main thread while the engines
/// themselves run their heavy work asynchronously.
///
/// Note: `FileScanner` and `FileOperations` are `ObservableObject`s. If a view needs to
/// update from their internal `@Published` changes (progress, busy state, etc.), prefer
/// observing those objects directly (e.g. `@ObservedObject`) rather than relying on this
/// wrapper to forward change notifications.
class AppViewModel: ObservableObject {
    // MARK: - Core engines used across the UI
    
    /// Scans folders and produces `ScanResults` (categorization, duplicates, suggestions).
    @Published var fileScanner = FileScanner()
    
    /// Executes cleanup actions (move/archive/delete/compress) and maintains an undo stack.
    @Published var fileOperations = FileOperations()
    
    /// Performs Xcode Derived Data cleanup via user-selected folder access.
    @Published var xcodeCleaner = XcodeCleaner()
    
    /// Manages sandbox-friendly folder permissions using security-scoped bookmarks.
    @Published var folderAccess = FolderAccessController()
}
