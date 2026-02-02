//
//  AppLogger.swift
//  StravX
//
//  Created by Claude Code
//  Copyright © 2026 StravX. All rights reserved.
//

import Foundation
import OSLog

/// Centralized logging utility using OSLog for production-ready logging
enum AppLogger {

    // MARK: - Log Categories

    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.jf.StravX"

    static let general = Logger(subsystem: subsystem, category: "General")
    static let location = Logger(subsystem: subsystem, category: "Location")
    static let territory = Logger(subsystem: subsystem, category: "Territory")
    static let activity = Logger(subsystem: subsystem, category: "Activity")
    static let team = Logger(subsystem: subsystem, category: "Team")
    static let notification = Logger(subsystem: subsystem, category: "Notification")
    static let user = Logger(subsystem: subsystem, category: "User")
    static let network = Logger(subsystem: subsystem, category: "Network")
    static let ui = Logger(subsystem: subsystem, category: "UI")
    static let data = Logger(subsystem: subsystem, category: "Data")

    // MARK: - Convenience Methods

    /// Log information message
    static func info(_ message: String, category: Logger = general) {
        category.info("\(message, privacy: .public)")
    }

    /// Log debug message (only in debug builds)
    static func debug(_ message: String, category: Logger = general) {
        #if DEBUG
        category.debug("\(message, privacy: .public)")
        #endif
    }

    /// Log warning message
    static func warning(_ message: String, category: Logger = general) {
        category.warning("\(message, privacy: .public)")
    }

    /// Log error message
    static func error(_ message: String, error: Error? = nil, category: Logger = general) {
        if let error = error {
            category.error("\(message, privacy: .public): \(error.localizedDescription, privacy: .public)")
        } else {
            category.error("\(message, privacy: .public)")
        }
    }

    /// Log critical error
    static func critical(_ message: String, error: Error? = nil, category: Logger = general) {
        if let error = error {
            category.critical("\(message, privacy: .public): \(error.localizedDescription, privacy: .public)")
        } else {
            category.critical("\(message, privacy: .public)")
        }
    }

    /// Log with custom privacy level
    static func log(_ message: String, type: OSLogType = .default, category: Logger = general) {
        category.log(level: type, "\(message, privacy: .public)")
    }
}

// MARK: - Emoji Helpers

extension AppLogger {
    /// Success emoji prefix
    static let success = "✅"

    /// Error emoji prefix
    static let failure = "❌"

    /// Warning emoji prefix
    static let warn = "⚠️"

    /// Info emoji prefix
    static let infoIcon = "ℹ️"

    /// Debug emoji prefix
    static let debugIcon = "🔍"

    /// Location emoji
    static let locationIcon = "📍"

    /// Activity emoji
    static let activityIcon = "🏃"

    /// Territory emoji
    static let territoryIcon = "🗺️"
}
