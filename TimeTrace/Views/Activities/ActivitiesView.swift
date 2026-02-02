//
//  ActivitiesView.swift
//  TimeTrace
//
//  Created by Claude Code on 2/2/26.
//

import SwiftUI
import SwiftData

struct ActivitiesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Activity.startTime, order: .reverse)
    private var activities: [Activity]

    @State private var showingAddActivity = false
    @State private var selectedDate = Date()

    var body: some View {
        NavigationStack {
            Group {
                if activities.isEmpty {
                    emptyStateView
                } else {
                    activityListView
                }
            }
            .navigationTitle("Activities")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddActivity = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddActivity) {
                AddActivityView()
            }
        }
    }

    private var emptyStateView: some View {
        ContentUnavailableView(
            "No Activities",
            systemImage: "clock.badge.questionmark",
            description: Text("Start tracking your time by adding your first activity.")
        )
    }

    private var activityListView: some View {
        List {
            ForEach(groupedActivities, id: \.date) { group in
                Section(header: Text(group.date, style: .date)) {
                    ForEach(group.activities) { activity in
                        ActivityListRow(activity: activity)
                    }
                    .onDelete { indexSet in
                        deleteActivities(from: group.activities, at: indexSet)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private var groupedActivities: [(date: Date, activities: [Activity])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: activities) { activity in
            calendar.startOfDay(for: activity.startTime)
        }
        return grouped
            .map { (date: $0.key, activities: $0.value) }
            .sorted { $0.date > $1.date }
    }

    private func deleteActivities(from activities: [Activity], at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(activities[index])
        }
    }
}

// MARK: - Activity List Row

struct ActivityListRow: View {
    let activity: Activity

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: activity.source.icon)
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(activity.title)
                    .font(.body)

                HStack(spacing: 8) {
                    Text(activity.formattedTimeRange)
                    if let tags = activity.tags, !tags.isEmpty {
                        Text("•")
                        Text(tags.map(\.name).joined(separator: ", "))
                            .lineLimit(1)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            Text(activity.formattedDuration)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Add Activity View (Placeholder)

struct AddActivityView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var title = ""
    @State private var notes = ""
    @State private var startTime = Date()
    @State private var endTime = Date()

    var body: some View {
        NavigationStack {
            Form {
                Section("Activity Details") {
                    TextField("What were you doing?", text: $title)
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Time") {
                    DatePicker("Start", selection: $startTime)
                    DatePicker("End", selection: $endTime)
                }

                Section("Tags") {
                    Text("Tag selection coming soon")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Log Activity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveActivity()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }

    private func saveActivity() {
        let activity = Activity(
            title: title,
            notes: notes.isEmpty ? nil : notes,
            startTime: startTime,
            endTime: endTime,
            source: .manual
        )
        modelContext.insert(activity)
        dismiss()
    }
}

#Preview {
    ActivitiesView()
        .modelContainer(for: [Activity.self, Tag.self])
}
