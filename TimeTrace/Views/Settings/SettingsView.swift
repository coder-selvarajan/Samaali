//
//  SettingsView.swift
//  TimeTrace
//
//  Created by Claude Code on 2/2/26.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @AppStorage(AppConstants.StorageKeys.activityGapThreshold)
    private var gapThreshold = AppConstants.ActivityTracking.defaultGapThresholdMinutes

    @AppStorage(AppConstants.StorageKeys.pomodoroFocusDuration)
    private var focusDuration = AppConstants.Pomodoro.defaultFocusDurationMinutes

    @AppStorage(AppConstants.StorageKeys.pomodoroShortBreak)
    private var shortBreakDuration = AppConstants.Pomodoro.defaultShortBreakMinutes

    @AppStorage(AppConstants.StorageKeys.pomodoroLongBreak)
    private var longBreakDuration = AppConstants.Pomodoro.defaultLongBreakMinutes

    @AppStorage(AppConstants.StorageKeys.enableScreenTimeImport)
    private var enableScreenTime = false

    @AppStorage(AppConstants.StorageKeys.enableAIInsights)
    private var enableAIInsights = true

    @AppStorage(AppConstants.StorageKeys.enableNotifications)
    private var enableNotifications = true

    var body: some View {
        NavigationStack {
            Form {
                // Activity Tracking
                Section {
                    Stepper(
                        "Prompt after \(gapThreshold) min gap",
                        value: $gapThreshold,
                        in: 15...180,
                        step: 15
                    )
                } header: {
                    Text("Activity Tracking")
                } footer: {
                    Text("Show a prompt to log activity when the app is opened after this duration of inactivity.")
                }

                // Pomodoro Settings
                Section("Pomodoro Timer") {
                    Stepper(
                        "Focus: \(focusDuration) min",
                        value: $focusDuration,
                        in: 5...60,
                        step: 5
                    )
                    Stepper(
                        "Short break: \(shortBreakDuration) min",
                        value: $shortBreakDuration,
                        in: 1...15,
                        step: 1
                    )
                    Stepper(
                        "Long break: \(longBreakDuration) min",
                        value: $longBreakDuration,
                        in: 10...30,
                        step: 5
                    )
                }

                // Integrations
                Section {
                    Toggle("Screen Time Import", isOn: $enableScreenTime)
                    Toggle("AI Insights", isOn: $enableAIInsights)
                } header: {
                    Text("Features")
                } footer: {
                    Text("Screen Time import requires additional permissions. AI insights are processed entirely on-device.")
                }

                // Notifications
                Section("Notifications") {
                    Toggle("Enable Notifications", isOn: $enableNotifications)
                }

                // Tags Management
                Section {
                    NavigationLink {
                        TagManagementView()
                    } label: {
                        Label("Manage Tags", systemImage: "tag")
                    }
                }

                // Data Management
                Section("Data") {
                    NavigationLink {
                        Text("Export functionality coming soon")
                            .foregroundStyle(.secondary)
                    } label: {
                        Label("Export Data", systemImage: "square.and.arrow.up")
                    }

                    NavigationLink {
                        Text("Import functionality coming soon")
                            .foregroundStyle(.secondary)
                    } label: {
                        Label("Import Data", systemImage: "square.and.arrow.down")
                    }
                }

                // About
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }

                    Link(destination: URL(string: "https://example.com/privacy")!) {
                        Label("Privacy Policy", systemImage: "hand.raised")
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

// MARK: - Tag Management View

struct TagManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Tag.name) private var tags: [Tag]

    @State private var showingAddTag = false

    var body: some View {
        List {
            Section("System Tags") {
                ForEach(tags.filter { $0.isSystem }) { tag in
                    TagRow(tag: tag)
                }
            }

            Section("Custom Tags") {
                ForEach(tags.filter { !$0.isSystem }) { tag in
                    TagRow(tag: tag)
                }
                .onDelete(perform: deleteCustomTags)

                Button {
                    showingAddTag = true
                } label: {
                    Label("Add Tag", systemImage: "plus")
                }
            }
        }
        .navigationTitle("Tags")
        .sheet(isPresented: $showingAddTag) {
            AddTagView()
        }
    }

    private func deleteCustomTags(at offsets: IndexSet) {
        let customTags = tags.filter { !$0.isSystem }
        for index in offsets {
            modelContext.delete(customTags[index])
        }
    }
}

// MARK: - Tag Row

struct TagRow: View {
    let tag: Tag

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(hex: tag.colorHex) ?? .blue)
                .frame(width: 24, height: 24)
                .overlay {
                    if let icon = tag.icon {
                        Image(systemName: icon)
                            .font(.caption2)
                            .foregroundStyle(.white)
                    }
                }

            Text(tag.name)

            Spacer()

            if tag.isSystem {
                Text("System")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Add Tag View

struct AddTagView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var name = ""
    @State private var selectedColor = "#007AFF"

    private let colorOptions = [
        "#007AFF", "#34C759", "#FF9500", "#FF2D55",
        "#5856D6", "#AF52DE", "#00C7BE", "#FF6482"
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Tag Name") {
                    TextField("Enter tag name", text: $name)
                }

                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 16) {
                        ForEach(colorOptions, id: \.self) { color in
                            Circle()
                                .fill(Color(hex: color) ?? .blue)
                                .frame(width: 44, height: 44)
                                .overlay {
                                    if color == selectedColor {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.white)
                                            .fontWeight(.bold)
                                    }
                                }
                                .onTapGesture {
                                    selectedColor = color
                                }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("New Tag")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        saveTag()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }

    private func saveTag() {
        let tag = Tag(name: name, colorHex: selectedColor, isSystem: false)
        modelContext.insert(tag)
        dismiss()
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [Tag.self])
}
