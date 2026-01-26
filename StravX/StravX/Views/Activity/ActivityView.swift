//
//  ActivityView.swift
//  StravX
//
//  Created by Claude Code
//  Copyright © 2026 StravX. All rights reserved.
//

import SwiftUI
import SwiftData

struct ActivityView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Activity.date, order: .reverse) private var activities: [Activity]
    @State private var showingNewActivity = false

    var body: some View {
        NavigationStack {
            Group {
                if activities.isEmpty {
                    emptyStateView
                } else {
                    activitiesListView
                }
            }
            .navigationTitle("Activités")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingNewActivity = true
                    } label: {
                        Label("Nouvelle activité", systemImage: "plus.circle.fill")
                            .font(.title3)
                    }
                }
            }
            .fullScreenCover(isPresented: $showingNewActivity) {
                NewActivityView()
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "figure.run.circle")
                .font(.system(size: 80))
                .foregroundColor(.blue)

            VStack(spacing: 8) {
                Text("Aucune activité")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Commencez votre première activité sportive")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                showingNewActivity = true
            } label: {
                Label("Démarrer une activité", systemImage: "play.fill")
                    .font(.headline)
                    .frame(maxWidth: 300)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Spacer()
        }
        .padding()
    }

    private var activitiesListView: some View {
        List {
            ForEach(activities) { activity in
                NavigationLink(destination: ActivityDetailView(activity: activity)) {
                    ActivityRowView(activity: activity)
                }
            }
            .onDelete(perform: deleteActivities)
        }
    }

    private func deleteActivities(at offsets: IndexSet) {
        for index in offsets {
            let activity = activities[index]
            modelContext.delete(activity)
        }
    }
}

struct ActivityRowView: View {
    let activity: Activity

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Image(systemName: activity.activityTypeIcon)
                    .font(.system(size: 32))
                    .foregroundColor(activity.isValid ? .blue : .red)
                    .frame(width: 50, height: 50)
                    .background((activity.isValid ? Color.blue : Color.red).opacity(0.1))
                    .cornerRadius(10)

                if !activity.isValid {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.red)
                        .offset(x: 20, y: -20)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(activity.activityTypeLabel)
                        .font(.headline)
                        .foregroundColor(activity.isValid ? .primary : .red)

                    if !activity.isValid {
                        Image(systemName: "xmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }

                Text(activity.date, style: .date)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                if !activity.isValid, let message = activity.validationMessage {
                    Text(message)
                        .font(.caption)
                        .foregroundColor(.red)
                        .lineLimit(1)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(activity.distanceFormatted)
                    .font(.headline)
                    .foregroundColor(activity.isValid ? .primary : .secondary)

                Text(activity.durationFormatted)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
        .opacity(activity.isValid ? 1.0 : 0.7)
    }
}

#Preview {
    ActivityView()
        .modelContainer(for: [Activity.self], inMemory: true)
}
