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
    @State private var requestedCategory: NoteCategory?
    @State private var deleteRequest: Bool = false
    @State private var renameRequest: Bool = false
    @State private var isDark: Bool = true
    
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
                    ForEach(categories) { category in
                        Text(category.categoryTitle)
                            .tag(category.categoryTitle)
                            .foregroundStyle(selectedTag == category.categoryTitle ? Color.primary : .gray)
                            .contextMenu {
                                Button("Rename") {
                                    categoryTitle = category.categoryTitle
                                    requestedCategory = category
                                    renameRequest = true
                                }
                                
                                Button("Delete") {
                                    categoryTitle = category.categoryTitle
                                    requestedCategory = category
                                    deleteRequest = true
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
        .alert("Rename Category", isPresented: $renameRequest) {
            TextField("Work", text: $categoryTitle)
            
            Button("Cancel", role: .cancel) {
                categoryTitle = ""
                requestedCategory = nil
            }
            
            Button("Rename") {
                if let requestedCategory = requestedCategory {
                    requestedCategory.categoryTitle = categoryTitle
                    categoryTitle = ""
                    self.requestedCategory = nil
                }
            }
        }
        .alert("Are you sure you want to delete this \(categoryTitle) category?", isPresented: $deleteRequest) {
            Button("Cancel", role: .cancel) {
                categoryTitle = ""
                requestedCategory = nil
            }
            
            Button("Delete", role: .destructive) {
                if let requestedCategory = requestedCategory {
                    context.delete(requestedCategory)
                    categoryTitle = ""
                    self.requestedCategory = nil
                }
            }
        }
        .toolbar {
            HStack(spacing: 10) {
                Button {
                    
                } label: {
                    Image(systemName: "plus")
                }
                
                Button {
                    isDark.toggle()
                } label: {
                    Image(systemName: isDark ? "sun.min" :  "moon")
                }
                .contentTransition(.symbolEffect(.replace))
            }
        }
        .preferredColorScheme(isDark ? .dark : .light)
    }
}
