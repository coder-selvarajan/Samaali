//
//  ActivityPromptView.swift
//  Samaali
//
//  Created by Claude Code on 2/2/26.
//

import SwiftUI
import SwiftData

/// Modal view shown when there's a gap in activity tracking
struct ActivityPromptView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    @Query(sort: \Tag.name) private var allTags: [Tag]

    @State private var activityTitle = ""
    @State private var notes = ""
    @State private var startTime = Date()
    @State private var endTime = Date()
    @State private var selectedTags: Set<UUID> = []
    @State private var showingQuickLog = true

    private let settingsService = SettingsService()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                promptHeader

                if showingQuickLog {
                    quickLogView
                } else {
                    detailedLogView
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Skip") {
                        skipPrompt()
                    }
                    .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Header

    private var promptHeader: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Theme.primary.opacity(0.1))
                    .frame(width: 80, height: 80)

                Image(systemName: "clock.badge.questionmark")
                    .font(.system(size: 36))
                    .foregroundStyle(Theme.primary)
            }

            VStack(spacing: 8) {
                Text("What have you been up to?")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text(gapDescription)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, 24)
        .padding(.horizontal)
    }

    private var gapDescription: String {
        let minutes = settingsService.activityGapThreshold
        if minutes >= 60 {
            let hours = minutes / 60
            return "It's been \(hours)+ hour\(hours > 1 ? "s" : "") since your last logged activity"
        }
        return "It's been \(minutes)+ minutes since your last logged activity"
    }

    // MARK: - Quick Log View

    private var quickLogView: some View {
        VStack(spacing: 20) {
            // Quick suggestions
            VStack(alignment: .leading, spacing: 12) {
                Text("Quick Log")
                    .font(.headline)
                    .padding(.horizontal)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(quickSuggestions, id: \.self) { suggestion in
                            QuickSuggestionButton(title: suggestion) {
                                quickLogActivity(suggestion)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.top, 24)

            Divider()
                .padding(.horizontal)

            // Custom entry
            VStack(spacing: 16) {
                TextField("Or describe what you were doing...", text: $activityTitle)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)

                HStack(spacing: 12) {
                    Button("Log Activity") {
                        logActivity()
                    }
                    .buttonStyle(.primary)
                    .disabled(activityTitle.isEmpty)

                    Button("More Details") {
                        withAnimation {
                            showingQuickLog = false
                        }
                    }
                    .buttonStyle(.secondary)
                }
            }

            Spacer()

            // Remind later option
            Button {
                remindLater()
            } label: {
                HStack {
                    Image(systemName: "bell.badge")
                    Text("Remind me in 30 minutes")
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
            .padding(.bottom, 24)
        }
    }

    // MARK: - Detailed Log View

    private var detailedLogView: some View {
        Form {
            Section("Activity") {
                TextField("What were you doing?", text: $activityTitle)

                TextField("Notes (optional)", text: $notes, axis: .vertical)
                    .lineLimit(2...4)
            }

            Section("Time") {
                DatePicker("Started", selection: $startTime)
                DatePicker("Ended", selection: $endTime)
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
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }
            }

            Section {
                Button("Save Activity") {
                    logActivity()
                }
                .buttonStyle(.primary)
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                .disabled(activityTitle.isEmpty)
            }
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Button("Quick Log") {
                    withAnimation {
                        showingQuickLog = true
                    }
                }
                .font(.subheadline)
            }
        }
    }

    // MARK: - Quick Suggestions

    private var quickSuggestions: [String] {
        [
            "Meeting",
            "Deep Work",
            "Email & Messages",
            "Break",
            "Lunch",
            "Commute",
            "Exercise",
            "Reading"
        ]
    }

    // MARK: - Actions

    private func quickLogActivity(_ title: String) {
        activityTitle = title
        logActivity()
    }

    private func logActivity() {
        let selectedTagObjects = allTags.filter { selectedTags.contains($0.id) }

        let activity = Activity(
            title: activityTitle,
            notes: notes.isEmpty ? nil : notes,
            startTime: startTime,
            endTime: endTime,
            source: .manual,
            tags: selectedTagObjects.isEmpty ? nil : selectedTagObjects
        )

        modelContext.insert(activity)
        settingsService.updateLastActivityEndTime(endTime)
        appState.showActivityPrompt = false
        dismiss()
    }

    private func skipPrompt() {
        appState.showActivityPrompt = false
        dismiss()
    }

    private func remindLater() {
        NotificationService.shared.scheduleActivityPrompt(afterMinutes: 30)
        appState.showActivityPrompt = false
        dismiss()
    }

    private func toggleTag(_ tag: Tag) {
        if selectedTags.contains(tag.id) {
            selectedTags.remove(tag.id)
        } else {
            selectedTags.insert(tag.id)
        }
    }
}

// MARK: - Quick Suggestion Button

struct QuickSuggestionButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(Theme.primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Theme.primary.opacity(0.1))
                .clipShape(Capsule())
        }
    }
}

// MARK: - Tag Chip

struct TagChip: View {
    let tag: Tag
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon = tag.icon {
                    Image(systemName: icon)
                        .font(.caption)
                }
                Text(tag.name)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundStyle(isSelected ? .white : tagColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? tagColor : tagColor.opacity(0.15))
            .clipShape(Capsule())
        }
    }

    private var tagColor: Color {
        Color(hex: tag.colorHex) ?? Theme.primary
    }
}

#Preview {
    ActivityPromptView()
        .environmentObject(AppState())
        .modelContainer(for: [Activity.self, Tag.self])
}
