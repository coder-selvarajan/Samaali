//
//  PomodoroViewModel.swift
//  Samaali
//
//  Created by Claude Code on 2/2/26.
//

import Foundation
import SwiftData
import Combine
import UserNotifications

/// ViewModel for the Pomodoro Timer with background support
@MainActor
@Observable
final class PomodoroViewModel {
    // MARK: - Timer State
    var currentSessionType: SessionType = .focus
    var timeRemaining: Int = 0
    var isRunning: Bool = false
    var completedFocusSessions: Int = 0

    // MARK: - Session Tracking
    var currentSession: PomodoroSession?
    var sessionStartTime: Date?

    // MARK: - Settings
    var focusDuration: Int
    var shortBreakDuration: Int
    var longBreakDuration: Int

    // MARK: - Dependencies
    private let modelContext: ModelContext
    private let settingsService: SettingsService
    private let notificationService: NotificationService
    private var timerCancellable: AnyCancellable?
    private var backgroundDate: Date?

    // MARK: - Computed Properties
    var totalDuration: Int {
        currentSessionType.getDuration(
            focus: focusDuration,
            shortBreak: shortBreakDuration,
            longBreak: longBreakDuration
        ) * 60
    }

    var progress: Double {
        guard totalDuration > 0 else { return 0 }
        return Double(totalDuration - timeRemaining) / Double(totalDuration)
    }

    var formattedTime: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var sessionTypeColor: Color {
        Theme.color(for: currentSessionType)
    }

    // MARK: - Initialization

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.settingsService = SettingsService()
        self.notificationService = NotificationService.shared

        // Load settings
        self.focusDuration = settingsService.pomodoroFocusDuration
        self.shortBreakDuration = settingsService.pomodoroShortBreak
        self.longBreakDuration = settingsService.pomodoroLongBreak

        // Initialize timer
        resetTimer(for: .focus)

        // Setup background handling
        setupBackgroundObservers()
    }

    func cleanup() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }

    // MARK: - Timer Controls

    func startTimer() {
        guard !isRunning else { return }

        isRunning = true
        sessionStartTime = Date()

        // Create session record
        createSessionRecord()

        // Schedule notification
        notificationService.schedulePomodoroComplete(
            duration: TimeInterval(timeRemaining),
            sessionType: currentSessionType
        )

        // Start timer
        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }

    func pauseTimer() {
        isRunning = false
        timerCancellable?.cancel()
        notificationService.cancelPomodoroNotifications()
    }

    func resetTimer(for sessionType: SessionType? = nil) {
        pauseTimer()

        if let sessionType = sessionType {
            currentSessionType = sessionType
        }

        timeRemaining = currentSessionType.getDuration(
            focus: focusDuration,
            shortBreak: shortBreakDuration,
            longBreak: longBreakDuration
        ) * 60

        sessionStartTime = nil
        currentSession = nil
    }

    func skipToNext() {
        completeSession(wasCompleted: false)
        moveToNextSession()
    }

    // MARK: - Timer Logic

    private func tick() {
        guard timeRemaining > 0 else {
            completeSession(wasCompleted: true)
            moveToNextSession()
            return
        }

        timeRemaining -= 1
    }

    private func completeSession(wasCompleted: Bool) {
        pauseTimer()

        // Update session record
        if let session = currentSession {
            session.endTime = Date()
            session.wasCompleted = wasCompleted

            // Create activity for completed focus sessions
            if currentSessionType == .focus && wasCompleted {
                createActivityFromSession(session)
            }
        }

        // Increment completed sessions for focus
        if currentSessionType == .focus && wasCompleted {
            completedFocusSessions += 1
        }
    }

    private func moveToNextSession() {
        if currentSessionType == .focus {
            if completedFocusSessions >= AppConstants.Pomodoro.sessionsBeforeLongBreak {
                currentSessionType = .longBreak
                completedFocusSessions = 0
            } else {
                currentSessionType = .shortBreak
            }
        } else {
            currentSessionType = .focus
        }

        resetTimer(for: currentSessionType)
    }

    // MARK: - Data Management

    private func createSessionRecord() {
        let session = PomodoroSession(
            type: currentSessionType,
            durationMinutes: currentSessionType.getDuration(
                focus: focusDuration,
                shortBreak: shortBreakDuration,
                longBreak: longBreakDuration
            ),
            startTime: Date()
        )
        modelContext.insert(session)
        currentSession = session
    }

    private func createActivityFromSession(_ session: PomodoroSession) {
        let activity = Activity(
            title: "Pomodoro Focus Session",
            notes: "Completed \(session.durationMinutes) minute focus session",
            startTime: session.startTime,
            endTime: session.endTime ?? Date(),
            source: .pomodoro,
            productivityScore: 0.9
        )
        modelContext.insert(activity)
        session.linkedActivity = activity

        // Update settings
        settingsService.updateLastActivityEndTime(activity.endTime ?? Date())
    }

    // MARK: - Background Support

    private func setupBackgroundObservers() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleEnterBackground()
            }
        }

        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleEnterForeground()
            }
        }
    }

    private func handleEnterBackground() {
        guard isRunning else { return }
        backgroundDate = Date()
    }

    private func handleEnterForeground() {
        guard isRunning, let backgroundDate = backgroundDate else { return }

        let elapsedSeconds = Int(Date().timeIntervalSince(backgroundDate))
        timeRemaining = max(0, timeRemaining - elapsedSeconds)

        self.backgroundDate = nil

        if timeRemaining <= 0 {
            completeSession(wasCompleted: true)
            moveToNextSession()
        }
    }

    // MARK: - Settings Reload

    func reloadSettings() {
        focusDuration = settingsService.pomodoroFocusDuration
        shortBreakDuration = settingsService.pomodoroShortBreak
        longBreakDuration = settingsService.pomodoroLongBreak

        if !isRunning {
            resetTimer(for: currentSessionType)
        }
    }
}

// MARK: - SessionType Extension

extension SessionType {
    func getDuration(focus: Int, shortBreak: Int, longBreak: Int) -> Int {
        switch self {
        case .focus: return focus
        case .shortBreak: return shortBreak
        case .longBreak: return longBreak
        }
    }
}

import SwiftUI
