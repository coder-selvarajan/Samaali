//
//  HabitService.swift
//  DayArc
//
//  Created by Claude Code on 3/8/26.
//

import Foundation
import SwiftData

@MainActor
final class HabitService {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - CRUD Operations

    @discardableResult
    func createHabit(
        name: String,
        icon: String = "checkmark.circle",
        colorHex: String = "#5856D6"
    ) -> Habit {
        let habit = Habit(name: name, icon: icon, colorHex: colorHex)
        modelContext.insert(habit)
        return habit
    }

    func deleteHabit(_ habit: Habit) {
        modelContext.delete(habit)
    }

    func archiveHabit(_ habit: Habit) {
        habit.isArchived = true
    }

    // MARK: - Queries

    func fetchActiveHabits() throws -> [Habit] {
        let descriptor = FetchDescriptor<Habit>(
            predicate: #Predicate { habit in
                !habit.isArchived
            },
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchAllHabits() throws -> [Habit] {
        let descriptor = FetchDescriptor<Habit>(
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        return try modelContext.fetch(descriptor)
    }

    // MARK: - Tracking

    func toggleHabit(_ habit: Habit, for date: Date) {
        let calendar = Calendar.current
        let targetDay = calendar.startOfDay(for: date)

        if let existingLog = habit.log(for: date) {
            existingLog.isCompleted.toggle()
            existingLog.completedAt = existingLog.isCompleted ? Date() : nil
        } else {
            let log = HabitLog(date: targetDay, isCompleted: true, completedAt: Date())
            log.habit = habit
            modelContext.insert(log)
        }
    }

    // MARK: - Analytics

    func completionRate(for habit: Habit, days: Int = 30) -> Double {
        let calendar = Calendar.current
        guard let startDate = calendar.date(byAdding: .day, value: -days, to: Date()) else { return 0 }
        let habitCreatedDay = calendar.startOfDay(for: habit.createdAt)
        let effectiveStart = max(calendar.startOfDay(for: startDate), habitCreatedDay)
        let today = calendar.startOfDay(for: Date())

        guard effectiveStart <= today else { return 0 }

        let totalDays = calendar.dateComponents([.day], from: effectiveStart, to: today).day! + 1
        guard totalDays > 0 else { return 0 }

        let completedCount = habit.logs?.filter { log in
            log.isCompleted && calendar.startOfDay(for: log.date) >= effectiveStart
        }.count ?? 0

        return Double(completedCount) / Double(totalDays)
    }
}
