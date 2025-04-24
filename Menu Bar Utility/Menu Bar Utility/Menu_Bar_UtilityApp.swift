//
//  Menu_Bar_UtilityApp.swift
//  Menu Bar Utility
//
//  Created by Israel Manzo on 4/23/25.
//

import SwiftUI

@main
struct Menu_Bar_UtilityApp: App {
    var body: some Scene {
        MenuBarExtra {
            ContentView()
        } label: {
            Text("Disk Analyser")
        }
        .menuBarExtraStyle(.window)
    }
}
