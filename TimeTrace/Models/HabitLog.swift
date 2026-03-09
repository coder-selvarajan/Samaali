//
//  HabitLog.swift
//  TimeTrace
//
//  Created by Claude Code on 3/8/26.
//

import Foundation
import SwiftData

@Model
final class HabitLog {
    var id: UUID
    var date: Date
    var isCompleted: Bool
    var completedAt: Date?

    var habit: Habit?

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        isCompleted: Bool = true,
        completedAt: Date? = Date()
    ) {
        self.id = id
        self.date = date
        self.isCompleted = isCompleted
        self.completedAt = completedAt
    }
}
