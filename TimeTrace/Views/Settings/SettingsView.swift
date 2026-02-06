//
//  SettingsView.swift
//  TimeTrace
//
//  Created by Claude Code on 2/2/26.
//

import SwiftUI
import SwiftData

// MARK: - Appearance Mode
enum AppearanceMode: Int, CaseIterable {
    case system = 0
    case light = 1
    case dark = 2

    var label: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

struct SettingsView: View {
    @AppStorage(AppConstants.StorageKeys.appearanceMode)
    private var appearanceMode: Int = AppearanceMode.system.rawValue

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
                // Appearance
                Section {
                    Picker("Appearance", selection: $appearanceMode) {
                        ForEach(AppearanceMode.allCases, id: \.rawValue) { mode in
                            Text(mode.label).tag(mode.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Appearance")
                } footer: {
                    Text("Choose how TimeTrace looks. System follows your device settings.")
                }

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
                    NavigationLink {
                        ScreenTimeSettingsView(enableScreenTime: $enableScreenTime)
                    } label: {
                        HStack {
                            Label("Screen Time", systemImage: "hourglass")
                            Spacer()
                            if enableScreenTime {
                                Text("Enabled")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    NavigationLink {
                        AIInsightsSettingsView(enableAIInsights: $enableAIInsights)
                    } label: {
                        HStack {
                            Label("AI Insights", systemImage: "sparkles")
                            Spacer()
                            if enableAIInsights {
                                Text("Enabled")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
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
                        .foregroundStyle(Theme.primary)
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
    @State private var selectedColor = "#5856D6"

    private let colorOptions = [
        "#5856D6", "#AF52DE", "#007AFF", "#34C759",
        "#FF9500", "#FF2D55", "#00C7BE", "#FF6482"
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
                    .fontWeight(.semibold)
                    .foregroundStyle(Theme.primary)
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

// MARK: - Screen Time Settings View

struct ScreenTimeSettingsView: View {
    @Binding var enableScreenTime: Bool
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: ScreenTimeViewModel?

    var body: some View {
        Form {
            Section {
                Toggle("Enable Screen Time Import", isOn: $enableScreenTime)
            } footer: {
                Text("When enabled, TimeTrace can import your Screen Time data to automatically track app usage.")
            }

            if enableScreenTime {
                Section("Authorization") {
                    if let vm = viewModel {
                        HStack {
                            Text("Status")
                            Spacer()
                            Text(vm.authorizationStatus.description)
                                .foregroundStyle(vm.isAuthorized ? Theme.success : .secondary)
                        }

                        if !vm.isAuthorized {
                            Button {
                                Task { await vm.requestAuthorization() }
                            } label: {
                                HStack {
                                    Image(systemName: "lock.open")
                                    Text("Request Access")
                                }
                            }
                        }
                    }
                }

                Section {
                    NavigationLink {
                        ScreenTimeView()
                    } label: {
                        Label("View Screen Time Data", systemImage: "chart.pie")
                    }
                }

                Section("About Screen Time Integration") {
                    VStack(alignment: .leading, spacing: 8) {
                        SettingsInfoRow(icon: "lock.shield", text: "All data stays on your device")
                        SettingsInfoRow(icon: "arrow.down.circle", text: "Import usage as activities")
                        SettingsInfoRow(icon: "tag", text: "Auto-categorize by app type")
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Screen Time")
        .onAppear {
            if viewModel == nil {
                viewModel = ScreenTimeViewModel(modelContext: modelContext)
            }
        }
    }
}

// MARK: - AI Insights Settings View

struct AIInsightsSettingsView: View {
    @Binding var enableAIInsights: Bool

    @AppStorage(AppConstants.StorageKeys.enableProductivityScoring)
    private var enableProductivityScoring = true

    @AppStorage(AppConstants.StorageKeys.enableSentimentAnalysis)
    private var enableSentimentAnalysis = true

    @AppStorage(AppConstants.StorageKeys.enablePatternDetection)
    private var enablePatternDetection = true

    var body: some View {
        Form {
            Section {
                Toggle("Enable AI Insights", isOn: $enableAIInsights)
            } footer: {
                Text("AI insights analyze your activity patterns to provide personalized recommendations and statistics.")
            }

            if enableAIInsights {
                Section("Analysis Features") {
                    Toggle("Productivity Scoring", isOn: $enableProductivityScoring)
                    Toggle("Sentiment Analysis", isOn: $enableSentimentAnalysis)
                    Toggle("Pattern Detection", isOn: $enablePatternDetection)
                }

                Section {
                    NavigationLink {
                        AIInsightsView()
                    } label: {
                        Label("View AI Insights", systemImage: "chart.bar.xaxis")
                    }
                }

                Section("Privacy") {
                    VStack(alignment: .leading, spacing: 8) {
                        SettingsInfoRow(icon: "iphone", text: "100% on-device processing")
                        SettingsInfoRow(icon: "xmark.icloud", text: "No cloud data transmission")
                        SettingsInfoRow(icon: "hand.raised", text: "Your data never leaves your device")
                    }
                    .padding(.vertical, 4)
                }

                Section("How It Works") {
                    VStack(alignment: .leading, spacing: 12) {
                        SettingsInfoRow(
                            icon: "waveform.path.ecg",
                            text: "Analyzes activity patterns over time"
                        )
                        SettingsInfoRow(
                            icon: "brain.head.profile",
                            text: "Uses Apple's NaturalLanguage framework"
                        )
                        SettingsInfoRow(
                            icon: "lightbulb",
                            text: "Generates personalized insights"
                        )
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("AI Insights")
    }
}

// MARK: - Settings Info Row

private struct SettingsInfoRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Theme.primary)
                .frame(width: 20)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [Tag.self])
}
