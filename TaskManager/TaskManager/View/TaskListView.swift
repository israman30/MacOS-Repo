//
//  TaskListView.swift
//  TaskManager
//
//  Created by Israel Manzo on 4/21/25.
//

import SwiftUI

struct TaskListView: View {
    let title: String
    @Binding var tasks: [Task]
    @State private var selectedTasks: Task? = nil
    @State private var isPresentedInspector: Bool = false
    var body: some View {
        List($tasks) { $task in
            TaskView(
                task: $task,
                selectedTask: $selectedTasks,
                isPresentedInspector: $isPresentedInspector
            )
        }
        .toolbar {
            ToolbarItemGroup {
                Button {
                    tasks.append(Task(title: "New Task"))
                } label: {
                    Label("Add new task", systemImage: "plus")
                }
                Button {
                    isPresentedInspector.toggle()
                } label: {
                    Label("Show Inspector", systemImage: "sidebar.right")
                }
            }
            
        }
        .inspector(isPresented: $isPresentedInspector) {
            Group {
                if let selectedTask = selectedTasks {
                    Text(selectedTask.title)
                        .font(.title)
                } else {
                    Text("Nothing selected")
                }
            }
            .frame(minWidth: 100, maxWidth: .infinity)
        }
    }
}

#Preview {
    TaskListView(title: "All", tasks: .constant(Task.exampples))
}
