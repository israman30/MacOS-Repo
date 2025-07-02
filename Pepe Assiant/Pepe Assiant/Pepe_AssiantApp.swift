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
                .background(Color(NSColor.windowBackgroundColor))
        }
//        .windowTitle("Pepe Assistant")
        .windowResizability(.contentSize)
        .defaultSize(width: 1000, height: 700)
    }
}
