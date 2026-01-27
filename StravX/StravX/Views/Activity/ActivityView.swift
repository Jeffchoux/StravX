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
            ZStack {
                // Contenu principal
                Group {
                    if activities.isEmpty {
                        emptyStateView
                    } else {
                        activitiesListView
                    }
                }

                // Bouton flottant toujours visible
                VStack {
                    Spacer()
                    HStack {
                        Spacer()

                        Button {
                            showingNewActivity = true
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "play.fill")
                                    .font(.title2)
                                Text("DÉMARRER")
                                    .font(.headline)
                                    .fontWeight(.bold)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [.orange, .red],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(30)
                            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, activities.isEmpty ? 100 : 30)
                    }
                }
            }
            .navigationTitle("Activités")
            .navigationBarTitleDisplayMode(.large)
            .fullScreenCover(isPresented: $showingNewActivity) {
                NewActivityView()
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "figure.run.circle")
                .font(.system(size: 100))
                .foregroundColor(.gray.opacity(0.5))

            VStack(spacing: 12) {
                Text("Prêt à bouger ?")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Appuyez sur DÉMARRER pour\ncommencer votre première activité")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                HStack(spacing: 4) {
                    Image(systemName: "arrow.down.right")
                        .font(.caption)
                    Text("Bouton en bas à droite")
                        .font(.caption)
                }
                .foregroundColor(.secondary.opacity(0.7))
                .padding(.top, 8)
            }

            Spacer()
            Spacer() // Extra spacer pour laisser de la place au bouton flottant
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
