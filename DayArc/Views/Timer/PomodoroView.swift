//
//  PomodoroView.swift
//  DayArc
//
//  Created by Claude Code on 2/2/26.
//

import SwiftUI
import SwiftData

struct PomodoroView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appState: AppState
    @State private var viewModel: PomodoroViewModel?
    @State private var showingTimerSettings = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                backgroundGradient

                VStack(spacing: 32) {
                    Spacer()

                    // Session Type Selector
                    sessionTypeSelector

                    // Timer Display
                    timerDisplay

                    // Progress Ring
                    progressRing

                    // Control Buttons
                    controlButtons

                    Spacer()

                    // Session Progress
                    sessionProgressIndicator

                    // Current Status
                    statusLabel
                }
                .padding()
            }
            .navigationTitle("Pomodoro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        appState.showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundStyle(Theme.primary)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingTimerSettings = true
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .foregroundStyle(Theme.primary)
                    }
                }
            }
            .sheet(isPresented: $showingTimerSettings) {
                PomodoroSettingsSheet(viewModel: viewModel)
            }
            .onAppear {
                initializeViewModel()
            }
        }
    }

    private func initializeViewModel() {
        if viewModel == nil {
            viewModel = PomodoroViewModel(modelContext: modelContext)
        }
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                sessionColor.opacity(0.1),
                Color(.systemBackground)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    // MARK: - Session Type Selector

    private var sessionTypeSelector: some View {
        HStack(spacing: 12) {
            ForEach(SessionType.allCases, id: \.self) { type in
                SessionTypeButton(
                    type: type,
                    isSelected: viewModel?.currentSessionType == type,
                    isDisabled: viewModel?.isRunning == true
                ) {
                    viewModel?.resetTimer(for: type)
                }
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Timer Display

    private var timerDisplay: some View {
        Text(viewModel?.formattedTime ?? "25:00")
            .font(.system(size: 72, weight: .light, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(sessionColor)
            .contentTransition(.numericText())
            .animation(.linear(duration: 0.1), value: viewModel?.timeRemaining)
    }

    // MARK: - Progress Ring

    private var progressRing: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(sessionColor.opacity(0.2), lineWidth: 12)

            // Progress ring
            Circle()
                .trim(from: 0, to: viewModel?.progress ?? 0)
                .stroke(
                    sessionColor,
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.5), value: viewModel?.progress)

            // Center icon
            VStack(spacing: 8) {
                Image(systemName: viewModel?.currentSessionType.icon ?? "brain.head.profile")
                    .font(.system(size: 40))
                    .foregroundStyle(sessionColor)

                Text(viewModel?.currentSessionType.rawValue ?? "Focus")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 220, height: 220)
    }

    // MARK: - Control Buttons

    private var controlButtons: some View {
        HStack(spacing: 40) {
            // Reset Button
            ControlButton(
                icon: "arrow.counterclockwise",
                color: .secondary,
                size: .small
            ) {
                viewModel?.resetTimer()
            }

            // Play/Pause Button
            ControlButton(
                icon: viewModel?.isRunning == true ? "pause.fill" : "play.fill",
                color: sessionColor,
                size: .large
            ) {
                if viewModel?.isRunning == true {
                    viewModel?.pauseTimer()
                } else {
                    viewModel?.startTimer()
                }
            }

            // Skip Button
            ControlButton(
                icon: "forward.fill",
                color: .secondary,
                size: .small
            ) {
                viewModel?.skipToNext()
            }
        }
    }

    // MARK: - Session Progress Indicator

    private var sessionProgressIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<AppConstants.Pomodoro.sessionsBeforeLongBreak, id: \.self) { index in
                Circle()
                    .fill(index < (viewModel?.completedFocusSessions ?? 0) ? Theme.success : Color(.systemGray4))
                    .frame(width: 12, height: 12)
                    .animation(.spring(response: 0.3), value: viewModel?.completedFocusSessions)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .clipShape(Capsule())
    }

    // MARK: - Status Label

    private var statusLabel: some View {
        Group {
            if viewModel?.isRunning == true {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Theme.success)
                        .frame(width: 8, height: 8)
                    Text("Session in progress")
                }
            } else if viewModel?.completedFocusSessions ?? 0 > 0 {
                Text("\(viewModel?.completedFocusSessions ?? 0) session\(viewModel?.completedFocusSessions == 1 ? "" : "s") completed today")
            } else {
                Text("Ready to focus")
            }
        }
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .padding(.bottom, 20)
    }

    // MARK: - Helpers

    private var sessionColor: Color {
        Theme.color(for: viewModel?.currentSessionType ?? .focus)
    }
}

// MARK: - Session Type Button

struct SessionTypeButton: View {
    let type: SessionType
    let isSelected: Bool
    let isDisabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: type.icon)
                    .font(.title3)
                Text(shortLabel)
                    .font(.caption2)
                    .fontWeight(.medium)
            }
            .foregroundStyle(isSelected ? .white : Theme.color(for: type))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? Theme.color(for: type) : Theme.color(for: type).opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(isDisabled)
        .opacity(isDisabled && !isSelected ? 0.5 : 1)
    }

    private var shortLabel: String {
        switch type {
        case .focus: return "Focus"
        case .shortBreak: return "Short"
        case .longBreak: return "Long"
        }
    }
}

// MARK: - Control Button

struct ControlButton: View {
    enum Size {
        case small, large

        var dimension: CGFloat {
            switch self {
            case .small: return 60
            case .large: return 80
            }
        }

        var iconFont: Font {
            switch self {
            case .small: return .title2
            case .large: return .title
            }
        }
    }

    let icon: String
    let color: Color
    let size: Size
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(size.iconFont)
                .foregroundStyle(size == .large ? .white : color)
                .frame(width: size.dimension, height: size.dimension)
                .background(size == .large ? color : Color(.systemGray5))
                .clipShape(Circle())
                .shadow(color: size == .large ? color.opacity(0.3) : .clear, radius: 8, y: 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Pomodoro Settings Sheet

struct PomodoroSettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    var viewModel: PomodoroViewModel?

    @AppStorage(AppConstants.StorageKeys.pomodoroFocusDuration)
    private var focusDuration = AppConstants.Pomodoro.defaultFocusDurationMinutes

    @AppStorage(AppConstants.StorageKeys.pomodoroShortBreak)
    private var shortBreak = AppConstants.Pomodoro.defaultShortBreakMinutes

    @AppStorage(AppConstants.StorageKeys.pomodoroLongBreak)
    private var longBreak = AppConstants.Pomodoro.defaultLongBreakMinutes

    var body: some View {
        NavigationStack {
            Form {
                Section("Durations") {
                    Stepper(value: $focusDuration, in: 1...60) {
                        HStack {
                            Label("Focus", systemImage: "brain.head.profile")
                            Spacer()
                            Text("\(focusDuration) min")
                                .foregroundStyle(.secondary)
                        }
                    }

                    Stepper(value: $shortBreak, in: 1...30) {
                        HStack {
                            Label("Short Break", systemImage: "cup.and.saucer.fill")
                            Spacer()
                            Text("\(shortBreak) min")
                                .foregroundStyle(.secondary)
                        }
                    }

                    Stepper(value: $longBreak, in: 1...60) {
                        HStack {
                            Label("Long Break", systemImage: "figure.walk")
                            Spacer()
                            Text("\(longBreak) min")
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section {
                    HStack {
                        Text("Sessions before long break")
                        Spacer()
                        Text("\(AppConstants.Pomodoro.sessionsBeforeLongBreak)")
                            .foregroundStyle(.secondary)
                    }
                } footer: {
                    Text("Complete \(AppConstants.Pomodoro.sessionsBeforeLongBreak) focus sessions to earn a long break.")
                }

                Section {
                    Button("Reset to Defaults") {
                        focusDuration = AppConstants.Pomodoro.defaultFocusDurationMinutes
                        shortBreak = AppConstants.Pomodoro.defaultShortBreakMinutes
                        longBreak = AppConstants.Pomodoro.defaultLongBreakMinutes
                    }
                    .foregroundStyle(.red)
                }
            }
            .navigationTitle("Timer Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        viewModel?.reloadSettings()
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    PomodoroView()
        .modelContainer(for: [PomodoroSession.self, Activity.self])
}
