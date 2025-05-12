//
//  ContentView.swift
//  Notes App
//
//  Created by Israel Manzo on 5/12/25.
//

import SwiftUI

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
    @State private var selectedTag: String?
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selectedTag) {
                Text("All notes")
                    .tag("All notes")
                Text("Favorites")
                    .tag("Favorites")
            }
        } detail: {
            
        }
        .navigationTitle(selectedTag ?? "Notes")

    }
}
