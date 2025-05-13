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
    var allCatrogories: [NoteCategory]
    @Query private var notes: [Note]
    
    init(category: String? = nil, allCatrogories: [NoteCategory]) {
        self.category = category
        self.allCatrogories = allCatrogories
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
                            .contextMenu {
                                Button {
                                    note.isFavorite.toggle()
                                } label: {
                                    Text(note.isFavorite ? "Remove from favorites" : "Add to favorites")
                                }
                                
                                Menu {
                                    ForEach(allCatrogories) { category in
                                        Button {
                                            note.category = category
                                        } label: {
                                            HStack(spacing: 5) {
                                                if category == note.category {
                                                    Image(systemName: "checkmark")
                                                        .font(.caption)
                                                }
                                                Text(category.categoryTitle)
                                            }
                                        }
                                        
                                        Button("Remove from category") {
                                            note.category = nil
                                        }
                                    }
                                } label: {
                                    Text("Category")
                                }
                            }
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
    NotesView(allCatrogories: [NoteCategory]([]))
}

struct CardView: View {
    @Bindable var note: Note
    var isKeyboardEnabled: FocusState<Bool>.Binding
    @State private var showNote: Bool = false
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(.clear)
            
            if showNote {
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
        .onAppear {
            showNote = true
        }
        .onDisappear {
            showNote = false
        }
    }
}
