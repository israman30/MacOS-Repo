//
//  TaskListView.swift
//  TaskManager
//
//  Created by Israel Manzo on 4/21/25.
//

import SwiftUI

struct StaticTaskListView: View {
    let title: String
    let tasks: [Task]
    var body: some View {
        List(tasks) { task in
            HStack {
                Image(systemName: task.isCompleted ? "checkmark.circle" : "circle")
                Text(task.title)
            }
        }
    }
}

#Preview {
    StaticTaskListView(title: "Task", tasks: Task.exampples)
}
