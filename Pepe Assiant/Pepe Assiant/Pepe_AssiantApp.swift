//
//  Pepe_AssiantApp.swift
//  Pepe Assiant
//
//  Created by Israel Manzo on 6/28/25.
//

import AppKit
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
        .windowResizability(.automatic)
        .defaultSize(width: 1000, height: 700)
        .commands {
            CommandMenu("NeatOS") {
                Button("About NeatOS") {
                    AboutPanelPresenter.show()
                }
                Button("How to use") {
                    NotificationCenter.default.post(name: .pepeShowTutorial, object: nil)
                }
                .keyboardShortcut("t", modifiers: [.command, .shift])
                Divider()
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

private enum AboutPanelPresenter {
    static func show() {
        DispatchQueue.main.async {
            NSApp.activate(ignoringOtherApps: true)
            NSApp.orderFrontStandardAboutPanel(options: [.applicationName: "NeatOS"])
        }
    }
}
