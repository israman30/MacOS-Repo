//
//  TaskView.swift
//  TaskManager
//
//  Created by Israel Manzo on 4/21/25.
//

import SwiftUI

struct TaskView: View {
    @Binding var task: Task
    @Binding var selectedTask: Task?
    @Binding var isPresentedInspector: Bool
    var body: some View {
        HStack {
            Image(systemName: task.isCompleted ? "checkmark.circle" : "circle")
                .onTapGesture {
                    task.isCompleted.toggle()
                }
            TextField("New Task", text: $task.title)
                .textFieldStyle(.plain)
            
            Button {
                isPresentedInspector = true
                selectedTask = task
            } label: {
                Text("More")
            }
        }
    }
}

#Preview {
    TaskView(task: .constant(Task.example), selectedTask: .constant(nil), isPresentedInspector: .constant(false))
        .padding()
}
