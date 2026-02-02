//
//  PomodoroView.swift
//  TimeTrace
//
//  Created by Claude Code on 2/2/26.
//

import SwiftUI

struct PomodoroView: View {
    @State private var selectedMode: SessionType = .focus
    @State private var timeRemaining: Int = AppConstants.Pomodoro.defaultFocusDurationMinutes * 60
    @State private var isRunning = false
    @State private var completedSessions = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()

                // Mode Selector
                modeSelector

                // Timer Display
                timerDisplay

                // Progress Ring
                progressRing

                // Controls
                controlButtons

                Spacer()

                // Session Counter
                sessionCounter
            }
            .padding()
            .navigationTitle("Pomodoro")
        }
    }

    // MARK: - Components

    private var modeSelector: some View {
        Picker("Mode", selection: $selectedMode) {
            ForEach(SessionType.allCases, id: \.self) { mode in
                Text(mode.rawValue).tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
        .onChange(of: selectedMode) { _, newValue in
            resetTimer(for: newValue)
        }
    }

    private var timerDisplay: some View {
        Text(formattedTime)
            .font(.system(size: 72, weight: .light, design: .rounded))
            .monospacedDigit()
    }

    private var progressRing: some View {
        ZStack {
            Circle()
                .stroke(Color(.systemGray5), lineWidth: 12)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    progressColor,
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.5), value: progress)

            Image(systemName: selectedMode.icon)
                .font(.system(size: 48))
                .foregroundStyle(progressColor.opacity(0.7))
        }
        .frame(width: 200, height: 200)
    }

    private var controlButtons: some View {
        HStack(spacing: 40) {
            // Reset Button
            Button {
                resetTimer(for: selectedMode)
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.title2)
                    .frame(width: 60, height: 60)
                    .background(Color(.systemGray5))
                    .clipShape(Circle())
            }

            // Play/Pause Button
            Button {
                isRunning.toggle()
            } label: {
                Image(systemName: isRunning ? "pause.fill" : "play.fill")
                    .font(.title)
                    .foregroundStyle(.white)
                    .frame(width: 80, height: 80)
                    .background(progressColor)
                    .clipShape(Circle())
            }

            // Skip Button
            Button {
                skipToNext()
            } label: {
                Image(systemName: "forward.fill")
                    .font(.title2)
                    .frame(width: 60, height: 60)
                    .background(Color(.systemGray5))
                    .clipShape(Circle())
            }
        }
    }

    private var sessionCounter: some View {
        HStack(spacing: 8) {
            ForEach(0..<AppConstants.Pomodoro.sessionsBeforeLongBreak, id: \.self) { index in
                Circle()
                    .fill(index < completedSessions ? Color.green : Color(.systemGray4))
                    .frame(width: 12, height: 12)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(Capsule())
    }

    // MARK: - Computed Properties

    private var formattedTime: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private var progress: CGFloat {
        let total = selectedMode.defaultDuration * 60
        return CGFloat(total - timeRemaining) / CGFloat(total)
    }

    private var progressColor: Color {
        switch selectedMode {
        case .focus: return .blue
        case .shortBreak: return .green
        case .longBreak: return .orange
        }
    }

    // MARK: - Actions

    private func resetTimer(for mode: SessionType) {
        isRunning = false
        timeRemaining = mode.defaultDuration * 60
    }

    private func skipToNext() {
        if selectedMode == .focus {
            completedSessions += 1
            if completedSessions >= AppConstants.Pomodoro.sessionsBeforeLongBreak {
                selectedMode = .longBreak
                completedSessions = 0
            } else {
                selectedMode = .shortBreak
            }
        } else {
            selectedMode = .focus
        }
        resetTimer(for: selectedMode)
    }
}

#Preview {
    PomodoroView()
}
