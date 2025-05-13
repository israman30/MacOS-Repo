//
//  NotesView.swift
//  Notes App
//
//  Created by Israel Manzo on 5/12/25.
//

import SwiftUI
import SwiftData

struct NotesView: View {
    var category: String?
    @Query private var notes: [Note]
    
    init(category: String? = nil) {
        self.category = category
        // dynamic filtering
        let predicate = #Predicate<Note> {
            $0.category?.categoryTitle == category
        }
        
        let favoritePredicate = #Predicate<Note> {
            $0.isFavorite
        }
        
        let finalPredicate = category == "All Notes" ? nil : (category == "Favorites" ? favoritePredicate : predicate)
        _notes = Query(filter: finalPredicate, sort: [], animation: .snappy)
    }
    
    var body: some View {
        GeometryReader { reader in
            let size = reader.size
            let width = size.width
            // dynamic grid
            let row = max(Int(width / 250), 1)
            ScrollView(.vertical) {
                LazyVGrid(
                    columns: Array(repeating: GridItem(spacing: 10), count: row),
                    spacing: 10
                ) {
                    
                }
                .padding(12)
            }
        }
    }
}

#Preview {
    NotesView()
}
