//
//  ActivitiesView.swift
//  DayArc
//
//  Created by Claude Code on 2/2/26.
//

import SwiftUI
import SwiftData

struct ActivitiesView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appState: AppState
    @Query(sort: \Activity.startTime, order: .reverse)
    private var activities: [Activity]

    @State private var showingAddActivity = false
    @State private var selectedActivity: Activity?
    @State private var searchText = ""

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
            .searchable(text: $searchText, prompt: "Search activities")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        appState.showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundStyle(Theme.primary)
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddActivity = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(Theme.primary)
                    }
                }
            }
            .sheet(isPresented: $showingAddActivity) {
                AddActivityView()
            }
            .sheet(item: $selectedActivity) { activity in
                ActivityDetailView(activity: activity)
            }
        }
    }

    private var filteredActivities: [Activity] {
        if searchText.isEmpty {
            return activities
        }
        return activities.filter { activity in
            activity.title.localizedCaseInsensitiveContains(searchText) ||
            (activity.notes?.localizedCaseInsensitiveContains(searchText) ?? false) ||
            (activity.tags?.contains { $0.name.localizedCaseInsensitiveContains(searchText) } ?? false)
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
                Section {
                    ForEach(group.activities) { activity in
                        ActivityListRow(activity: activity)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedActivity = activity
                            }
                    }
                    .onDelete { indexSet in
                        deleteActivities(from: group.activities, at: indexSet)
                    }
                } header: {
                    HStack {
                        Text(formatSectionDate(group.date))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Spacer()
                        Text(formatTotalDuration(for: group.activities))
                            .font(.caption)
                            .foregroundStyle(Theme.primary)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private var groupedActivities: [(date: Date, activities: [Activity])] {
        let calendar = Calendar.current
        let filtered = filteredActivities
        let grouped = Dictionary(grouping: filtered) { activity in
            calendar.startOfDay(for: activity.startTime)
        }
        return grouped
            .map { (date: $0.key, activities: $0.value) }
            .sorted { $0.date > $1.date }
    }

    private func formatSectionDate(_ date: Date) -> String {
        if date.isToday {
            return "Today"
        } else if date.isYesterday {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
    }

    private func formatTotalDuration(for activities: [Activity]) -> String {
        let totalMinutes = activities.compactMap(\.durationInMinutes).reduce(0, +)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        if hours > 0 {
            return "\(hours)h \(minutes)m total"
        }
        return "\(minutes)m total"
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
            // Source Icon
            Circle()
                .fill(Theme.primary.opacity(0.15))
                .frame(width: 40, height: 40)
                .overlay {
                    Image(systemName: activity.source.icon)
                        .font(.body)
                        .foregroundStyle(Theme.primary)
                }

            // Details
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(activity.title)
                        .font(.body)
                        .fontWeight(.medium)

                    if activity.isOngoing {
                        Text("LIVE")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Theme.success)
                            .clipShape(Capsule())
                    }
                }

                HStack(spacing: 6) {
                    Text(activity.formattedTimeRange)

                    if let tags = activity.tags, !tags.isEmpty {
                        Text("•")
                        HStack(spacing: 4) {
                            ForEach(tags.prefix(2)) { tag in
                                Text(tag.name)
                                    .foregroundStyle(Color(hex: tag.colorHex) ?? Theme.primary)
                            }
                            if tags.count > 2 {
                                Text("+\(tags.count - 2)")
                            }
                        }
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            // Duration
            VStack(alignment: .trailing, spacing: 2) {
                Text(activity.formattedDuration)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Theme.primary)

                if let score = activity.productivityScore {
                    ProductivityBadge(score: score)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Productivity Badge

struct ProductivityBadge: View {
    let score: Double

    private var category: ProductivityCategory {
        switch score {
        case 0..<0.3: return .low
        case 0.3..<0.7: return .medium
        default: return .high
        }
    }

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: "bolt.fill")
                .font(.caption2)
            Text(category.rawValue)
                .font(.caption2)
        }
        .foregroundStyle(Color(hex: category.color) ?? .gray)
    }
}

// MARK: - Add Activity View

struct AddActivityView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Tag.name) private var allTags: [Tag]

    @State private var title = ""
    @State private var notes = ""
    @State private var startTime = Date().addingTimeInterval(-3600)
    @State private var endTime = Date()
    @State private var selectedTags: Set<UUID> = []
    @State private var isOngoing = false

    private let settingsService = SettingsService()

    var body: some View {
        NavigationStack {
            Form {
                Section("Activity Details") {
                    TextField("What were you doing?", text: $title)

                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }

                Section("Time") {
                    DatePicker("Started", selection: $startTime)

                    Toggle("Still ongoing", isOn: $isOngoing)

                    if !isOngoing {
                        DatePicker("Ended", selection: $endTime)
                    }
                }

                if !allTags.isEmpty {
                    Section("Tags") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(allTags) { tag in
                                    TagChip(
                                        tag: tag,
                                        isSelected: selectedTags.contains(tag.id)
                                    ) {
                                        toggleTag(tag)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    }
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
                    .fontWeight(.semibold)
                    .foregroundStyle(Theme.primary)
                    .disabled(title.isEmpty)
                }
            }
        }
    }

    private func toggleTag(_ tag: Tag) {
        if selectedTags.contains(tag.id) {
            selectedTags.remove(tag.id)
        } else {
            selectedTags.insert(tag.id)
        }
    }

    private func saveActivity() {
        let selectedTagObjects = allTags.filter { selectedTags.contains($0.id) }

        let activity = Activity(
            title: title,
            notes: notes.isEmpty ? nil : notes,
            startTime: startTime,
            endTime: isOngoing ? nil : endTime,
            source: .manual,
            tags: selectedTagObjects.isEmpty ? nil : selectedTagObjects
        )

        modelContext.insert(activity)

        if !isOngoing {
            settingsService.updateLastActivityEndTime(endTime)
        }

        dismiss()
    }
}

// MARK: - Activity Detail View

struct ActivityDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let activity: Activity

    @State private var isEditing = false
    @State private var editedTitle: String = ""
    @State private var editedNotes: String = ""

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if isEditing {
                        TextField("Title", text: $editedTitle)
                    } else {
                        LabeledContent("Activity", value: activity.title)
                    }

                    LabeledContent("Duration", value: activity.formattedDuration)
                    LabeledContent("Time", value: activity.formattedTimeRange)
                    LabeledContent("Source", value: activity.source.rawValue)
                }

                if let notes = activity.notes, !notes.isEmpty {
                    Section("Notes") {
                        if isEditing {
                            TextField("Notes", text: $editedNotes, axis: .vertical)
                        } else {
                            Text(notes)
                                .font(.body)
                        }
                    }
                }

                if let tags = activity.tags, !tags.isEmpty {
                    Section("Tags") {
                        FlowLayout(spacing: 8) {
                            ForEach(tags) { tag in
                                HStack(spacing: 4) {
                                    if let icon = tag.icon {
                                        Image(systemName: icon)
                                    }
                                    Text(tag.name)
                                }
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color(hex: tag.colorHex)?.opacity(0.2) ?? Theme.primary.opacity(0.2))
                                .foregroundStyle(Color(hex: tag.colorHex) ?? Theme.primary)
                                .clipShape(Capsule())
                            }
                        }
                    }
                }

                if activity.productivityScore != nil || activity.energyLevel != nil {
                    Section("Insights") {
                        if let score = activity.productivityScore {
                            LabeledContent("Productivity") {
                                ProductivityBadge(score: score)
                            }
                        }

                        if let energy = activity.energyLevel {
                            LabeledContent("Energy Level", value: "\(energy)/5")
                        }

                        if let mood = activity.moodLevel {
                            LabeledContent("Mood", value: "\(mood)/5")
                        }
                    }
                }

                Section {
                    Button("Delete Activity", role: .destructive) {
                        modelContext.delete(activity)
                        dismiss()
                    }
                }
            }
            .navigationTitle("Activity Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button(isEditing ? "Save" : "Edit") {
                        if isEditing {
                            activity.title = editedTitle
                            activity.notes = editedNotes.isEmpty ? nil : editedNotes
                            activity.updatedAt = Date()
                        } else {
                            editedTitle = activity.title
                            editedNotes = activity.notes ?? ""
                        }
                        isEditing.toggle()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                      y: bounds.minY + result.positions[index].y),
                         proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }

                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
            }

            self.size = CGSize(width: maxWidth, height: y + rowHeight)
        }
    }
}

#Preview {
    ActivitiesView()
        .modelContainer(for: [Activity.self, Tag.self])
}
