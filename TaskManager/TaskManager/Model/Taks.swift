//
//  Taks.swift
//  TaskManager
//
//  Created by Israel Manzo on 4/21/25.
//

import Foundation

struct Task: Identifiable, Hashable {
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
        [
            Task(title: "Buy milk", isCompleted: false, dueDate: Date().addingTimeInterval(60 * 60 * 24)),
            Task(title: "Go to school", isCompleted: false, dueDate: Date().addingTimeInterval(60 * 60 * 24)),
            Task(title: "Clean the house", isCompleted: false, dueDate: Date().addingTimeInterval(60 * 60 * 24)),
            Task(title: "Go to get that", isCompleted: false, dueDate: Date().addingTimeInterval(60 * 60 * 24)),
            Task(title: "Gum time", isCompleted: false, dueDate: Date().addingTimeInterval(60 * 60 * 24))
        ]
    }
}

struct TaskGroup: Identifiable, Hashable {
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

enum TaskSection: Identifiable, CaseIterable, Hashable {
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
    
    var displayName: String {
        switch self {
        case .all:
            "All"
        case .done:
            "Done"
        case .upcoming:
            "Upcoming"
        case .list(let taskGroup):
            taskGroup.title
        }
    }
    
    var iconName: String {
        switch self {
        case .all:
            "star"
        case .done:
            "checkmark.circle"
        case .upcoming:
            "calendar"
        case .list:
            "folder"
        }
    }
    
    static var allCases: [TaskSection] {
        [.all, .done, .upcoming]
    }
    
    static func == (lhs: TaskSection, rhs: TaskSection) -> Bool {
        lhs.id == rhs.id
    }
    
}

