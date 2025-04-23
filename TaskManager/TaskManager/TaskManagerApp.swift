//
//  TaskManagerApp.swift
//  TaskManager
//
//  Created by Israel Manzo on 4/21/25.
//

import SwiftUI

@main
struct TaskManagerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .commands {
            CommandMenu("Task") {
                Button("Add new task") {
                    
                }
            }
            
            CommandGroup(after: .newItem) {
                Button("Add new group") {
                    
                }
            }
        }
        WindowGroup("Special Window") {
            Text("Special window content")
                .frame(minWidth: 200, idealWidth: 300, minHeight: 200)
        }
        .windowStyle(.automatic)
        
        Settings {
            Text("Settings")
        }
        
        MenuBarExtra("Menu") {
            Button("Do something") { }
        }
        
    }
}
