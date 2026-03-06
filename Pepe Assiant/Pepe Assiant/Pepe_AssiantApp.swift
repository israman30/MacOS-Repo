//
//  Pepe_AssiantApp.swift
//  Pepe Assiant
//
//  Created by Israel Manzo on 6/28/25.
//

import SwiftUI

@main
struct Pepe_AssiantApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 800, minHeight: 600)
                .background(AppTheme.surface)
                .tint(AppTheme.primary)
        }
//        .windowTitle("NeatOS")
        .windowResizability(.contentSize)
        .defaultSize(width: 1000, height: 700)
        .commands {
            CommandMenu("NeatOS") {
                Button("Scan Desktop") {
                    NotificationCenter.default.post(name: .pepeScanDesktop, object: nil)
                }
                .keyboardShortcut("1", modifiers: .command)
                Button("Scan Downloads") {
                    NotificationCenter.default.post(name: .pepeScanDownloads, object: nil)
                }
                .keyboardShortcut("2", modifiers: .command)
                Button("Scan Documents") {
                    NotificationCenter.default.post(name: .pepeScanDocuments, object: nil)
                }
                .keyboardShortcut("3", modifiers: .command)
                Divider()
                Button(XcodeCleanerText.chipTitle) {
                    NotificationCenter.default.post(name: .pepeClearDerivedData, object: nil)
                }
                .keyboardShortcut("d", modifiers: [.command, .shift])
                Divider()
                Button("\(UIText.undo) Last Action") {
                    NotificationCenter.default.post(name: .pepeUndo, object: nil)
                }
                .keyboardShortcut("z", modifiers: [.command, .shift])
            }
        }
    }
}
