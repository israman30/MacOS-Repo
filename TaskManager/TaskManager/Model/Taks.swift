//
//  Taks.swift
//  TaskManager
//
//  Created by Israel Manzo on 4/21/25.
//

import Foundation

struct Task: Identifiable {
    var id = UUID()
    var title: String
    var isCompleted: Bool
    var dueDate: Date
    var details: String?
    
    init(title: String, isCompleted: Bool = false, dueDate: Date = Date(), details: String? = nil) {
        self.title = title
        self.isCompleted = isCompleted
        self.dueDate = dueDate
        self.details = details
    }
    
    static var example: Task {
        Task(title: "Buy milk", isCompleted: false, dueDate: Date().addingTimeInterval(60 * 60 * 24))
    }
    
    static var exampples: [Task] {
        [example, example, example]
    }
}

struct TaskGroup: Identifiable {
    var id = UUID()
    var title: String
    var creatingDate: Date
    var tasks: [Task]
    
    init(title: String, tasks: [Task] = []) {
        self.title = title
        self.creatingDate = Date()
        self.tasks = tasks
    }
    
    static func example() -> TaskGroup {
        let task1 = Task(title: "Today")
        let task2 = Task(title: "Tomorrow")
        let task3 = Task(title: "Yesterday")
        
        var group = TaskGroup(title: "Group of Task")
        return group
    }
    
    static func exampples() -> [TaskGroup] {
        let group1 = TaskGroup.example()
        let group2 = TaskGroup(title: "New Task")
        return [group1, group2]
    }
}

enum TaskSection: Identifiable {
    case all
    case done
    case upcoming
    case list(TaskGroup)
    
    var id: String {
        switch self {
        case .all:
            "all"
        case .done:
            "Done"
        case .upcoming:
            "Upcoming"
        case .list(let taskGroup):
            taskGroup.id.uuidString
        }
    }
}
