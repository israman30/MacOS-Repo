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
    
    @FocusState private var isKeyboardEnabled: Bool
    
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
                    ForEach(notes) { note in
                        CardView(note: note, isKeyboardEnabled: $isKeyboardEnabled)
                    }
                }
                .padding(12)
            }
            .onTapGesture {
                isKeyboardEnabled = false
            }
        }
    }
}

#Preview {
    NotesView()
}

struct CardView: View {
    @Bindable var note: Note
    var isKeyboardEnabled: FocusState<Bool>.Binding
    
    var body: some View {
        TextEditor(text: $note.content)
            .focused(isKeyboardEnabled)
            .overlay(alignment: .leading, content: {
                Text("Finish work")
                    .foregroundStyle(.gray)
                    .padding(.leading, 5)
                    .opacity(note.content.isEmpty ? 1 : 0)
                    .allowsHitTesting(true)
            })
            .scrollContentBackground(.hidden)
            .multilineTextAlignment(.leading)
            .padding(15)
            .kerning(1.2)
            .frame(maxWidth: .infinity)
            .background(.gray.opacity(0.01), in: .rect(cornerRadius: 12))
    }
}
