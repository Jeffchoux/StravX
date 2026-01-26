//
//  ProfileView.swift
//  StravX
//
//  Created by Claude Code
//  Copyright © 2026 StravX. All rights reserved.
//

import SwiftUI
import SwiftData

struct ProfileView: View {
    @Query(sort: \Activity.date, order: .reverse) private var activities: [Activity]
    @State private var showingSettings = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.blue)

                        Text("Mon Profil")
                            .font(.title)
                            .fontWeight(.bold)

                        Text("Athlète StravX")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()

                    // Stats globales
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Statistiques")
                            .font(.headline)
                            .padding(.horizontal)

                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            GlobalStatCard(
                                icon: "figure.run",
                                title: "Activités valides",
                                value: "\(validActivities.count)"
                            )

                            GlobalStatCard(
                                icon: "location.fill",
                                title: "Distance totale",
                                value: String(format: "%.1f km", totalDistance)
                            )

                            GlobalStatCard(
                                icon: "clock.fill",
                                title: "Temps total",
                                value: formatTotalTime(totalDuration)
                            )

                            GlobalStatCard(
                                icon: "speedometer",
                                title: "Vitesse moy.",
                                value: String(format: "%.1f km/h", avgSpeed)
                            )
                        }
                        .padding(.horizontal)
                    }

                    // Activités récentes
                    if !activities.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Activités récentes")
                                    .font(.headline)

                                Spacer()

                                if activities.count > 3 {
                                    Text("\(activities.count) au total")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.horizontal)

                            ForEach(activities.prefix(3)) { activity in
                                RecentActivityCard(activity: activity)
                                    .padding(.horizontal)
                            }
                        }
                    }

                    Spacer(minLength: 40)
                }
                .padding(.vertical)
            }
            .navigationTitle("Profil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
    }

    // Computed properties
    private var validActivities: [Activity] {
        activities.filter { $0.isValid }
    }

    private var totalDistance: Double {
        validActivities.reduce(0) { $0 + $1.distanceKm }
    }

    private var totalDuration: TimeInterval {
        validActivities.reduce(0) { $0 + $1.duration }
    }

    private var avgSpeed: Double {
        guard !validActivities.isEmpty else { return 0 }
        return validActivities.reduce(0) { $0 + $1.avgSpeed } / Double(validActivities.count)
    }

    private func formatTotalTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

struct GlobalStatCard: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(.blue)

            VStack(spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)

                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

struct RecentActivityCard: View {
    let activity: Activity

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Image(systemName: activity.activityTypeIcon)
                    .font(.title2)
                    .foregroundColor(activity.isValid ? .blue : .red)
                    .frame(width: 44, height: 44)
                    .background((activity.isValid ? Color.blue : Color.red).opacity(0.1))
                    .cornerRadius(10)

                if !activity.isValid {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundColor(.red)
                        .offset(x: 16, y: -16)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(activity.activityTypeLabel)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(activity.isValid ? .primary : .red)

                    if !activity.isValid {
                        Image(systemName: "xmark.circle.fill")
                            .font(.caption2)
                            .foregroundColor(.red)
                    }
                }

                Text(activity.date, format: Date.FormatStyle(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)

                if !activity.isValid, let message = activity.validationMessage {
                    Text(message)
                        .font(.caption2)
                        .foregroundColor(.red)
                        .lineLimit(1)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(activity.distanceFormatted)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(activity.isValid ? .primary : .secondary)

                Text(activity.durationFormatted)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(activity.isValid ? Color(.systemGray6) : Color.red.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(activity.isValid ? Color.clear : Color.red.opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview {
    ProfileView()
        .modelContainer(for: [Activity.self], inMemory: true)
}
