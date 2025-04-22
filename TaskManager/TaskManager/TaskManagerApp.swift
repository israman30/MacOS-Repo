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
    }
}
