//
//  ContentView.swift
//  MacLandmark from Apple
//
//  Created by Israel Manzo on 4/21/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Text("Hello SwiftUI App on macOS")
                .padding()
                .font(.title)
            
            Image(systemName: "applelogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
                .imageScale(.large)
                .foregroundStyle(.tint)
                .padding()
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
