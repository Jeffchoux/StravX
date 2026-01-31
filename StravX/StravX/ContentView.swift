//
//  ContentView.swift
//  StravX
//
//  Created by Claude Code
//  Copyright © 2026 StravX. All rights reserved.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedTab = 1

    var body: some View {
        TabView(selection: $selectedTab) {
            MapView()
                .tabItem {
                    Label("Carte", systemImage: "map")
                }
                .tag(0)

            ActivityView()
                .tabItem {
                    Label("Activité", systemImage: "figure.run")
                }
                .tag(1)

            ConquestView()
                .tabItem {
                    Label("Territoires", systemImage: "flag.fill")
                }
                .tag(2)

            EnhancedProfileView()
                .tabItem {
                    Label("Profil", systemImage: "person.circle")
                }
                .tag(3)
        }
        .accentColor(.orange)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Activity.self], inMemory: true)
}
