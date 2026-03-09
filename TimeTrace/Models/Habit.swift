//
//  Habit.swift
//  TimeTrace
//
//  Created by Claude Code on 3/8/26.
//

import Foundation
import SwiftData

@Model
final class Habit {
    var id: UUID
    var name: String
    var icon: String
    var colorHex: String
    var createdAt: Date
    var isArchived: Bool

    @Relationship(deleteRule: .cascade, inverse: \HabitLog.habit)
    var logs: [HabitLog]?

    init(
        id: UUID = UUID(),
        name: String,
        icon: String = "checkmark.circle",
        colorHex: String = "#5856D6",
        createdAt: Date = Date(),
        isArchived: Bool = false
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.createdAt = createdAt
        self.isArchived = isArchived
    }

    // MARK: - Computed Properties

    var color: String { colorHex }

    var currentStreak: Int {
        guard let logs = logs else { return 0 }
        let calendar = Calendar.current
        let completedDates = Set(logs.filter { $0.isCompleted }.map { calendar.startOfDay(for: $0.date) })

        var streak = 0
        var checkDate = calendar.startOfDay(for: Date())

        // If today isn't completed, start checking from yesterday
        if !completedDates.contains(checkDate) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: checkDate) else { return 0 }
            checkDate = yesterday
        }

        while completedDates.contains(checkDate) {
            streak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = previousDay
        }

        return streak
    }

    func isCompletedOn(_ date: Date) -> Bool {
        guard let logs = logs else { return false }
        let calendar = Calendar.current
        let targetDay = calendar.startOfDay(for: date)
        return logs.contains { log in
            log.isCompleted && calendar.startOfDay(for: log.date) == targetDay
        }
    }

    func log(for date: Date) -> HabitLog? {
        guard let logs = logs else { return nil }
        let calendar = Calendar.current
        let targetDay = calendar.startOfDay(for: date)
        return logs.first { calendar.startOfDay(for: $0.date) == targetDay }
    }
}
