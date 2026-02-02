//
//  HomeView.swift
//  TimeTrace
//
//  Created by Claude Code on 2/2/26.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Activity.startTime, order: .reverse)
    private var recentActivities: [Activity]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Welcome Section
                    welcomeSection

                    // Quick Stats
                    quickStatsSection

                    // Today's Timeline (placeholder)
                    todayTimelineSection

                    // Recent Activities
                    recentActivitiesSection
                }
                .padding()
            }
            .navigationTitle("TimeTrace")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {}) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
        }
    }

    // MARK: - Sections

    private var welcomeSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(greeting)
                .font(.title2)
                .fontWeight(.semibold)
            Text(Date(), style: .date)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var quickStatsSection: some View {
        HStack(spacing: 12) {
            StatCard(
                title: "Today",
                value: "0h",
                subtitle: "tracked",
                icon: "clock.fill",
                color: .blue
            )
            StatCard(
                title: "Productive",
                value: "0h",
                subtitle: "focus time",
                icon: "bolt.fill",
                color: .green
            )
            StatCard(
                title: "Sessions",
                value: "0",
                subtitle: "pomodoros",
                icon: "timer",
                color: .orange
            )
        }
    }

    private var todayTimelineSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Timeline")
                .font(.headline)

            RoundedRectangle(cornerRadius: AppConstants.UI.cornerRadius)
                .fill(Color(.systemGray6))
                .frame(height: 120)
                .overlay {
                    Text("Timeline chart will appear here")
                        .foregroundStyle(.secondary)
                }
        }
    }

    private var recentActivitiesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Activities")
                    .font(.headline)
                Spacer()
                Button("See All") {}
                    .font(.subheadline)
            }

            if recentActivities.isEmpty {
                emptyStateView
            } else {
                ForEach(recentActivities.prefix(5)) { activity in
                    ActivityRowView(activity: activity)
                }
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "clock.badge.questionmark")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text("No activities yet")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("Tap + to log your first activity")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    // MARK: - Helpers

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }
}

// MARK: - Stat Card Component

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Spacer()
            }

            Text(value)
                .font(.title2)
                .fontWeight(.bold)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: AppConstants.UI.cornerRadius))
    }
}

// MARK: - Activity Row Component

struct ActivityRowView: View {
    let activity: Activity

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay {
                    Image(systemName: activity.source.icon)
                        .foregroundStyle(.blue)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(activity.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(activity.formattedTimeRange)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(activity.formattedDuration)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: AppConstants.UI.cornerRadius))
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [Activity.self, Tag.self])
}
