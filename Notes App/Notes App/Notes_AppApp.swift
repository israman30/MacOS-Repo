//
//  Notes_AppApp.swift
//  Notes App
//
//  Created by Israel Manzo on 5/12/25.
//

import SwiftUI

@main
struct Notes_AppApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        // App data model
        .modelContainer(for: [Note.self, NoteCategory.self])
    }
}
