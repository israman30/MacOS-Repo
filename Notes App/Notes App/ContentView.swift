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
                    }
                } header: {
                    HStack {
                        Text("Categories")
                        Button {
                            
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

    }
}
