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
    @State private var searchText: String = ""
    var body: some View {
        NavigationSplitView {
            SideBarView(
                userCreatorGroup: $userCreatroGroup,
                selectedSection: $selection
            )
        } detail: {
            if searchText.isEmpty {
                switch selection {
                case .all:
                    TaskListView(title: "All", tasks: $allTasks)
                case .done:
                    StaticTaskListView(title: "All", tasks: allTasks.filter { $0.isCompleted })
                case .upcoming:
                    StaticTaskListView(title: "All", tasks: allTasks)
                case .list(let taskGroup):
                    StaticTaskListView(title: taskGroup.title, tasks: taskGroup.tasks)
                }
            } else {
                StaticTaskListView(title: "All", tasks: allTasks.filter { $0.title.contains(searchText) })
            }
            
        }
        .searchable(text: $searchText)
    }
}

#Preview {
    ContentView()
}
