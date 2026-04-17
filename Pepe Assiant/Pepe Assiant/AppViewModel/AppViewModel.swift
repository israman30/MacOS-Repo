//
//  AppViewModel.swift
//  Pepe Assiant
//
//  Created by Israel Manzo on 4/17/26.
//

import SwiftUI

@MainActor
class AppViewModel: ObservableObject {
    @Published var fileScanner = FileScanner()
    @Published var fileOperations = FileOperations()
    @Published var xcodeCleaner = XcodeCleaner()
    @Published var folderAccess = FolderAccessController()
}
