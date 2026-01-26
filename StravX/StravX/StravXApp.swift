//
//  StravXApp.swift
//  StravX
//
//  Created by Claude Code
//  Copyright © 2026 StravX. All rights reserved.
//

import SwiftUI
import SwiftData

@main
struct StravXApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Activity.self])
    }
}
