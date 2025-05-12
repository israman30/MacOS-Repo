//
//  ContentView.swift
//  Notes App
//
//  Created by Israel Manzo on 5/12/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
       HomeView()
            .frame(minWidth: 320, minHeight: 400)
    }
}

#Preview {
    ContentView()
}

struct HomeView: View {
    @State private var selectedTag: String? = "All Notes"
    // Query categories
    @Query(animation: .snappy) private var categories: [NoteCategory] = []
    @State private var addCategory: Bool = false
    @State private var categoryTitle: String = ""
    @Environment(\.modelContext) private var context
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selectedTag) {
                Text("All notes")
                    .tag("All notes")
                    .foregroundStyle(selectedTag == "All notes" ? Color.primary : .gray)
                
                Text("Favorites")
                    .tag("Favorites")
                    .foregroundStyle(selectedTag == "Favorites" ? Color.primary : .gray)
                
                Section {
                    ForEach(categories) {
                        Text($0.categoryTitle)
                            .tag($0.categoryTitle)
                            .foregroundStyle(selectedTag == $0.categoryTitle ? Color.primary : .gray)
                            .contextMenu {
                                Button("Rename") {
                                    
                                }
                                
                                Button("Delete") {
                                    
                                }
                            }
                    }
                } header: {
                    HStack {
                        Text("Categories")
                        Button {
                            addCategory.toggle()
                        } label: {
                            Image(systemName: "plus")
                                
                        }
                        .tint(.gray)
                        .buttonStyle(.plain)
                    }
                }
            }
        } detail: {
            
        }
        .navigationTitle(selectedTag ?? "Notes")
        .alert("Add Category", isPresented: $addCategory) {
            TextField("Work", text: $categoryTitle)
            
            Button("Cancel", role: .cancel) {
                categoryTitle = ""
            }
            
            Button("Add") {
                let newCategory = NoteCategory(categoryTitle: categoryTitle)
                context.insert(newCategory)
                categoryTitle = ""
            }
        }

    }
}
