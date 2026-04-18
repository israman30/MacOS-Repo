    //
//  ContentView.swift
//  Pepe Assiant
//
//  Created by Israel Manzo on 6/28/25.
//

import SwiftUI

struct ContentView: View {
    @AppStorage(AppStorageKeys.hasSeenOnboarding) private var hasSeenOnboarding = false
    @State private var showingOnboarding = false

    var body: some View {
        BotAssistantView()
            .sheet(isPresented: $showingOnboarding) {
                Group {
                    OnboardingView(isPresented: $showingOnboarding) {
                        hasSeenOnboarding = true
                    }
                }
                .applyInteractiveDismissDisabled()
            }
            .onAppear {
                if !hasSeenOnboarding {
                    showingOnboarding = true
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .pepeShowTutorial)) { _ in
                showingOnboarding = true
            }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

private extension View {
    @ViewBuilder
    func applyInteractiveDismissDisabled() -> some View {
        if #available(macOS 12.0, *) {
            self.interactiveDismissDisabled()
        } else {
            self
        }
    }
}
