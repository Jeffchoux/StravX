//
//  AppConstants.swift
//  StravX
//
//  Created by Claude Code
//  Copyright © 2026 StravX. All rights reserved.
//

import Foundation

/// Central constants for the StravX application
enum AppConstants {

    // MARK: - Activity Validation

    enum ActivityLimits {
        /// Walking: max realistic speed in km/h
        static let walkingMaxSpeed: Double = 8.0

        /// Running: max realistic speed in km/h
        static let runningMaxSpeed: Double = 25.0

        /// Cycling: max realistic speed in km/h
        static let cyclingMaxSpeed: Double = 60.0

        /// Walking: max peak speed in km/h
        static let walkingMaxPeakSpeed: Double = 12.0

        /// Running: max peak speed in km/h
        static let runningMaxPeakSpeed: Double = 35.0

        /// Cycling: max peak speed in km/h
        static let cyclingMaxPeakSpeed: Double = 80.0

        /// Minimum distance to be valid (meters)
        static let minValidDistance: Double = 10.0

        /// Maximum duration for minimal distance (seconds)
        static let maxDurationForMinDistance: TimeInterval = 300.0
    }

    // MARK: - Activity Type Detection

    enum SpeedThresholds {
        /// Walking threshold (km/h)
        static let walkingMax: Double = 6.0

        /// Running threshold (km/h)
        static let runningMax: Double = 15.0

        /// Cycling threshold (km/h)
        static let cyclingMax: Double = 35.0
    }

    // MARK: - Location Tracking

    enum Location {
        /// Distance filter when idle (meters)
        static let idleDistanceFilter: Double = 50.0

        /// Distance filter when tracking (meters)
        static let activeDistanceFilter: Double = 10.0

        /// Max distance between points to filter GPS errors (meters)
        static let maxPointDistance: Double = 100.0

        /// Territory check interval (seconds)
        static let territoryCheckInterval: TimeInterval = 3.0
    }

    // MARK: - Territory System

    enum Territory {
        /// Initial strength for neutral territory capture
        static let neutralCaptureStrength: Int = 10

        /// Initial strength for enemy territory capture
        static let attackCaptureStrength: Int = 25

        /// Strength gain on reinforcement
        static let reinforcementGain: Int = 10

        /// Bonus strength on successful defense
        static let defenseBonus: Int = 20

        /// Maximum strength
        static let maxStrength: Int = 100

        /// Weak territory threshold
        static let weakThreshold: Int = 30

        /// Strong territory threshold
        static let strongThreshold: Int = 70

        /// XP for neutral capture
        static let neutralCaptureXP: Int = 10

        /// XP for attack capture (standard)
        static let attackCaptureXP: Int = 25

        /// XP for strong enemy capture
        static let strongEnemyCaptureXP: Int = 50

        /// XP for reinforcement
        static let reinforcementXP: Int = 5

        /// XP for successful defense
        static let defenseXP: Int = 50

        /// Territory cleanup radius (meters)
        static let cleanupRadius: Double = 5000.0

        /// Territory load radius (meters)
        static let loadRadius: Double = 1000.0

        /// Max capture history events to keep
        static let maxHistoryEvents: Int = 10
    }

    // MARK: - Teams

    enum Teams {
        /// Maximum team members
        static let maxMembers: Int = 10

        /// Team code prefix
        static let codePrefix: String = "STRVX"

        /// Team code length (after prefix)
        static let codeLength: Int = 4
    }

    // MARK: - Achievements

    enum Achievements {
        /// Defender badge threshold
        static let defenderThreshold: Int = 10

        /// Badge unlock XP bonus
        static let badgeXP: Int = 100
    }

    // MARK: - UI

    enum UI {
        /// Notification display duration (seconds)
        static let notificationDuration: TimeInterval = 2.0

        /// Stat card icon size
        static let statCardIconSize: CGFloat = 30.0

        /// Stat card icon frame
        static let statCardIconFrame: CGFloat = 60.0
    }
}
