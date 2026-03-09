//
//  PomodoroSession.swift
//  DayArc
//
//  Created by Claude Code on 2/2/26.
//

import Foundation
import SwiftData

@Model
final class PomodoroSession {
    var id: UUID
    var type: SessionType
    var durationMinutes: Int
    var startTime: Date
    var endTime: Date?
    var wasCompleted: Bool
    var createdAt: Date

    var linkedActivity: Activity?

    var linkedTask: UserTask?

    var isOngoing: Bool {
        endTime == nil
    }

    init(
        id: UUID = UUID(),
        type: SessionType = .focus,
        durationMinutes: Int = AppConstants.Pomodoro.defaultFocusDurationMinutes,
        startTime: Date = Date(),
        endTime: Date? = nil,
        wasCompleted: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.type = type
        self.durationMinutes = durationMinutes
        self.startTime = startTime
        self.endTime = endTime
        self.wasCompleted = wasCompleted
        self.createdAt = createdAt
    }
}

// MARK: - Session Type
enum SessionType: String, Codable, CaseIterable {
    case focus = "Focus"
    case shortBreak = "Short Break"
    case longBreak = "Long Break"

    var icon: String {
        switch self {
        case .focus: return "brain.head.profile"
        case .shortBreak: return "cup.and.saucer.fill"
        case .longBreak: return "figure.walk"
        }
    }

    var defaultDuration: Int {
        switch self {
        case .focus: return AppConstants.Pomodoro.defaultFocusDurationMinutes
        case .shortBreak: return AppConstants.Pomodoro.defaultShortBreakMinutes
        case .longBreak: return AppConstants.Pomodoro.defaultLongBreakMinutes
        }
    }
}
