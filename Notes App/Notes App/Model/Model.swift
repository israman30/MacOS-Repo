//
//  Model.swift
//  Notes App
//
//  Created by Israel Manzo on 5/12/25.
//

import SwiftUI
import SwiftData

@Model
class Note {
    var content: String
    var isFavorite: Bool = false
    var category: NoteCategory?
    
    init(content: String, category: NoteCategory? = nil) {
        self.content = content
        self.category = category
    }
}

@Model
class NoteCategory {
    var categoryTitle: String = ""
    @Relationship(deleteRule: .cascade, inverse: \Note.category)
    var notes: [Note]?
    
    init(categoryTitle: String) {
        self.categoryTitle = categoryTitle
    }
}
