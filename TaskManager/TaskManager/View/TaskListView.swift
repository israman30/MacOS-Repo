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
    var body: some View {
        List(tasks) { task in
            HStack {
                Image(systemName: task.isCompleted ? "checkmark.circle" : "circle")
                Text(task.title)
            }
        }
        .toolbar {
            Button {
                
            } label: {
                Label("Add new task", systemImage: "plus")
            }
        }
    }
}

#Preview {
    TaskListView(title: "All", tasks: .constant(Task.exampples))
}
