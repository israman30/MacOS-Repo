//
//  ContentView.swift
//  TaskManager
//
//  Created by Israel Manzo on 4/21/25.
//

import SwiftUI

struct ContentView: View {
    @State private var userCreatroGroup: [TaskGroup] = TaskGroup.exampples()
    @State private var selection: TaskSection = .all
    @State private var allTasks = Task.exampples
    var body: some View {
        NavigationSplitView {
            SideBarView(
                userCreatorGroup: $userCreatroGroup,
                selectedSection: $selection
            )
        } detail: {
            switch selection {
            case .all:
                TaskListView(title: "All", tasks: allTasks)
            case .done:
                TaskListView(title: "Done", tasks: allTasks.filter { $0.isCompleted })
            case .upcoming:
                TaskListView(title: "All", tasks: allTasks)
            case .list(let taskGroup):
                TaskListView(title: taskGroup.title, tasks: taskGroup.tasks)
            }
            
        }

    }
}

#Preview {
    ContentView()
}
