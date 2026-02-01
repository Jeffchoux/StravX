//
//  NotificationManager.swift
//  StravX
//
//  Created by Claude Code
//  Copyright © 2026 StravX. All rights reserved.
//

import Foundation
import UserNotifications
import SwiftData
import UIKit

@Observable
class NotificationManager {
    private let center = UNUserNotificationCenter.current()
    private let modelContext: ModelContext

    var isAuthorized = false
    var authorizationStatus: UNAuthorizationStatus = .notDetermined

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        checkAuthorizationStatus()
    }

    // MARK: - Authorization

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            await MainActor.run {
                self.isAuthorized = granted
            }
            checkAuthorizationStatus()
            return granted
        } catch {
            print("❌ Error requesting notification authorization: \(error)")
            return false
        }
    }

    func checkAuthorizationStatus() {
        center.getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.authorizationStatus = settings.authorizationStatus
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }

    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    // MARK: - Territory Notifications

    /// Envoyer une notification quand un territoire est attaqué
    func notifyTerritoryAttacked(territory: Territory, attackerName: String) {
        guard isAuthorized else { return }
        guard isNotificationsEnabled() else { return }

        let content = UNMutableNotificationContent()
        content.title = "⚔️ Territoire Attaqué !"
        content.body = "\(attackerName) attaque votre territoire ! Force: \(territory.strengthPoints)%"
        content.sound = .default
        content.badge = NSNumber(value: 1)
        content.categoryIdentifier = "TERRITORY_ATTACK"
        content.userInfo = [
            "territoryID": territory.tileID,
            "type": "attack"
        ]

        // Déclencher immédiatement
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "attack_\(territory.tileID)_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error = error {
                print("❌ Error scheduling notification: \(error)")
            } else {
                print("✅ Territory attack notification scheduled")
            }
        }
    }

    /// Notification quand un territoire est perdu
    func notifyTerritoryLost(territory: Territory, capturedBy: String) {
        guard isAuthorized else { return }
        guard isNotificationsEnabled() else { return }

        let content = UNMutableNotificationContent()
        content.title = "🚨 Territoire Perdu !"
        content.body = "\(capturedBy) a capturé votre territoire. Reconquérez-le rapidement !"
        content.sound = .defaultCritical
        content.badge = NSNumber(value: 1)
        content.categoryIdentifier = "TERRITORY_LOST"
        content.userInfo = [
            "territoryID": territory.tileID,
            "type": "lost"
        ]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "lost_\(territory.tileID)_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error = error {
                print("❌ Error scheduling notification: \(error)")
            } else {
                print("✅ Territory lost notification scheduled")
            }
        }
    }

    /// Notification quand un territoire devient faible
    func notifyTerritoryWeak(territory: Territory) {
        guard isAuthorized else { return }
        guard isNotificationsEnabled() else { return }

        let content = UNMutableNotificationContent()
        content.title = "⚠️ Territoire Affaibli"
        content.body = "Votre territoire est faible (\(territory.strengthPoints)%). Renforcez-le en passant par là !"
        content.sound = .default
        content.categoryIdentifier = "TERRITORY_WEAK"
        content.userInfo = [
            "territoryID": territory.tileID,
            "type": "weak"
        ]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "weak_\(territory.tileID)_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error = error {
                print("❌ Error scheduling notification: \(error)")
            } else {
                print("✅ Territory weak notification scheduled")
            }
        }
    }

    // MARK: - Achievement Notifications

    /// Notification pour un nouveau badge débloqué
    func notifyBadgeUnlocked(badge: Badge) {
        guard isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title = "🏆 Nouveau Badge !"
        content.body = "Vous avez débloqué '\(badge.type.title)' ! +100 XP"
        content.sound = .default
        content.categoryIdentifier = "BADGE_UNLOCKED"

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "badge_\(badge.id)_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error = error {
                print("❌ Error scheduling notification: \(error)")
            } else {
                print("✅ Badge unlock notification scheduled")
            }
        }
    }

    /// Notification pour level up
    func notifyLevelUp(newLevel: Int) {
        guard isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title = "🎉 Level Up !"
        content.body = "Félicitations ! Vous êtes maintenant niveau \(newLevel)"
        content.sound = .default
        content.categoryIdentifier = "LEVEL_UP"

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "levelup_\(newLevel)_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error = error {
                print("❌ Error scheduling notification: \(error)")
            } else {
                print("✅ Level up notification scheduled")
            }
        }
    }

    // MARK: - Social Notifications

    /// Notification quand quelqu'un vous suit
    func notifyNewFollower(followerName: String) {
        guard isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title = "👥 Nouveau Follower"
        content.body = "\(followerName) suit maintenant vos exploits !"
        content.sound = .default
        content.categoryIdentifier = "NEW_FOLLOWER"

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "follower_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error = error {
                print("❌ Error scheduling notification: \(error)")
            } else {
                print("✅ New follower notification scheduled")
            }
        }
    }

    // MARK: - Daily Reminders

    /// Notification de rappel quotidien
    func scheduleDailyReminder(hour: Int = 18, minute: Int = 0) {
        guard isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title = "🏃 Temps de bouger !"
        content.body = "N'oubliez pas votre activité quotidienne pour maintenir votre série !"
        content.sound = .default
        content.categoryIdentifier = "DAILY_REMINDER"

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "daily_reminder",
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error = error {
                print("❌ Error scheduling daily reminder: \(error)")
            } else {
                print("✅ Daily reminder scheduled for \(hour):\(minute)")
            }
        }
    }

    func removeDailyReminder() {
        center.removePendingNotificationRequests(withIdentifiers: ["daily_reminder"])
    }

    // MARK: - Helpers

    private func isNotificationsEnabled() -> Bool {
        // Check AppStorage setting
        UserDefaults.standard.bool(forKey: "notificationsEnabled")
    }

    func clearAllNotifications() {
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
        // Clear badge using iOS 17+ API
        if #available(iOS 17.0, *) {
            center.setBadgeCount(0)
        } else {
            UIApplication.shared.applicationIconBadgeNumber = 0
        }
    }

    func clearBadge() {
        // Clear badge using iOS 17+ API
        if #available(iOS 17.0, *) {
            center.setBadgeCount(0)
        } else {
            UIApplication.shared.applicationIconBadgeNumber = 0
        }
    }
}

// MARK: - Notification Categories

extension NotificationManager {
    func registerNotificationCategories() {
        let territoryAttackCategory = UNNotificationCategory(
            identifier: "TERRITORY_ATTACK",
            actions: [],
            intentIdentifiers: [],
            options: .customDismissAction
        )

        let territoryLostCategory = UNNotificationCategory(
            identifier: "TERRITORY_LOST",
            actions: [],
            intentIdentifiers: [],
            options: .customDismissAction
        )

        let territoryWeakCategory = UNNotificationCategory(
            identifier: "TERRITORY_WEAK",
            actions: [],
            intentIdentifiers: [],
            options: .customDismissAction
        )

        let badgeUnlockedCategory = UNNotificationCategory(
            identifier: "BADGE_UNLOCKED",
            actions: [],
            intentIdentifiers: [],
            options: []
        )

        let levelUpCategory = UNNotificationCategory(
            identifier: "LEVEL_UP",
            actions: [],
            intentIdentifiers: [],
            options: []
        )

        let newFollowerCategory = UNNotificationCategory(
            identifier: "NEW_FOLLOWER",
            actions: [],
            intentIdentifiers: [],
            options: []
        )

        let dailyReminderCategory = UNNotificationCategory(
            identifier: "DAILY_REMINDER",
            actions: [],
            intentIdentifiers: [],
            options: []
        )

        center.setNotificationCategories([
            territoryAttackCategory,
            territoryLostCategory,
            territoryWeakCategory,
            badgeUnlockedCategory,
            levelUpCategory,
            newFollowerCategory,
            dailyReminderCategory
        ])
    }
}
