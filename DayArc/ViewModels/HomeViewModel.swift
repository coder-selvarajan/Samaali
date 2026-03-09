//
//  HomeViewModel.swift
//  DayArc
//
//  Created by Claude Code on 2/2/26.
//

import Foundation
import SwiftData
import Combine

/// ViewModel for the Home Dashboard
@MainActor
@Observable
final class HomeViewModel {
    // MARK: - Published Data
    var todayActivities: [Activity] = []
    var weekActivities: [Activity] = []
    var todayTotalMinutes: Int = 0
    var productiveMinutes: Int = 0
    var pomodoroSessionsToday: Int = 0
    var dailyChartData: [DailyChartPoint] = []
    var categoryBreakdown: [CategoryBreakdownItem] = []

    // MARK: - Dependencies
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Data Loading

    func loadDashboardData() {
        loadTodayActivities()
        loadWeekActivities()
        loadPomodoroSessions()
        calculateCategoryBreakdown()
        generateDailyChartData()
    }

    private func loadTodayActivities() {
        let today = Date()
        let startOfDay = today.startOfDay
        let endOfDay = today.endOfDay

        let descriptor = FetchDescriptor<Activity>(
            predicate: #Predicate { activity in
                activity.startTime >= startOfDay && activity.startTime <= endOfDay
            },
            sortBy: [SortDescriptor(\Activity.startTime, order: .reverse)]
        )

        do {
            todayActivities = try modelContext.fetch(descriptor)
            todayTotalMinutes = todayActivities
                .compactMap(\.durationInMinutes)
                .reduce(0, +)

            productiveMinutes = todayActivities
                .filter { $0.productivityCategory == .high || $0.productivityCategory == .medium }
                .compactMap(\.durationInMinutes)
                .reduce(0, +)
        } catch {
            print("Failed to fetch today's activities: \(error)")
        }
    }

    private func loadWeekActivities() {
        let calendar = Calendar.current
        let today = Date()
        guard let weekStart = calendar.date(byAdding: .day, value: -6, to: today.startOfDay) else { return }

        let descriptor = FetchDescriptor<Activity>(
            predicate: #Predicate { activity in
                activity.startTime >= weekStart
            },
            sortBy: [SortDescriptor(\Activity.startTime)]
        )

        do {
            weekActivities = try modelContext.fetch(descriptor)
        } catch {
            print("Failed to fetch week activities: \(error)")
        }
    }

    private func loadPomodoroSessions() {
        let today = Date()
        let startOfDay = today.startOfDay
        let endOfDay = today.endOfDay

        // Fetch completed sessions for today, then filter by type in memory
        // (SwiftData #Predicate doesn't support enum rawValue access)
        let descriptor = FetchDescriptor<PomodoroSession>(
            predicate: #Predicate { session in
                session.startTime >= startOfDay &&
                session.startTime <= endOfDay &&
                session.wasCompleted == true
            }
        )

        do {
            let sessions = try modelContext.fetch(descriptor)
            pomodoroSessionsToday = sessions.filter { $0.type == .focus }.count
        } catch {
            print("Failed to fetch pomodoro sessions: \(error)")
        }
    }

    private func calculateCategoryBreakdown() {
        var tagDurations: [String: Int] = [:]
        var untaggedMinutes = 0

        for activity in todayActivities {
            guard let minutes = activity.durationInMinutes else { continue }

            if let tags = activity.tags, !tags.isEmpty {
                for tag in tags {
                    tagDurations[tag.name, default: 0] += minutes / tags.count
                }
            } else {
                untaggedMinutes += minutes
            }
        }

        var breakdown: [CategoryBreakdownItem] = tagDurations.map { name, minutes in
            CategoryBreakdownItem(name: name, minutes: minutes, color: Theme.primary)
        }

        if untaggedMinutes > 0 {
            breakdown.append(CategoryBreakdownItem(name: "Other", minutes: untaggedMinutes, color: .secondary))
        }

        categoryBreakdown = breakdown.sorted { $0.minutes > $1.minutes }
    }

    private func generateDailyChartData() {
        let calendar = Calendar.current
        let today = Date()

        dailyChartData = (0..<7).reversed().compactMap { daysAgo in
            guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: today) else { return nil }

            let dayActivities = weekActivities.filter {
                calendar.isDate($0.startTime, inSameDayAs: date)
            }

            let totalMinutes = dayActivities.compactMap(\.durationInMinutes).reduce(0, +)

            return DailyChartPoint(
                date: date,
                totalMinutes: totalMinutes,
                productiveMinutes: dayActivities
                    .filter { $0.productivityCategory == .high }
                    .compactMap(\.durationInMinutes)
                    .reduce(0, +)
            )
        }
    }

    // MARK: - Formatted Values

    var formattedTodayTotal: String {
        formatDuration(minutes: todayTotalMinutes)
    }

    var formattedProductiveTime: String {
        formatDuration(minutes: productiveMinutes)
    }

    private func formatDuration(minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60

        if hours > 0 {
            return "\(hours)h \(mins)m"
        }
        return "\(mins)m"
    }
}

// MARK: - Chart Data Models

struct DailyChartPoint: Identifiable {
    let id = UUID()
    let date: Date
    let totalMinutes: Int
    let productiveMinutes: Int

    var dayLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }

    var totalHours: Double {
        Double(totalMinutes) / 60.0
    }

    var productiveHours: Double {
        Double(productiveMinutes) / 60.0
    }
}

struct CategoryBreakdownItem: Identifiable {
    let id = UUID()
    let name: String
    let minutes: Int
    let color: Color

    var formattedDuration: String {
        let hours = minutes / 60
        let mins = minutes % 60

        if hours > 0 {
            return "\(hours)h \(mins)m"
        }
        return "\(mins)m"
    }
}

// MARK: - Preview Helpers

extension HomeViewModel {
    static func preview(modelContext: ModelContext) -> HomeViewModel {
        let vm = HomeViewModel(modelContext: modelContext)
        vm.todayTotalMinutes = 385
        vm.productiveMinutes = 240
        vm.pomodoroSessionsToday = 6

        vm.dailyChartData = [
            DailyChartPoint(date: Calendar.current.date(byAdding: .day, value: -6, to: Date())!, totalMinutes: 320, productiveMinutes: 180),
            DailyChartPoint(date: Calendar.current.date(byAdding: .day, value: -5, to: Date())!, totalMinutes: 410, productiveMinutes: 220),
            DailyChartPoint(date: Calendar.current.date(byAdding: .day, value: -4, to: Date())!, totalMinutes: 280, productiveMinutes: 150),
            DailyChartPoint(date: Calendar.current.date(byAdding: .day, value: -3, to: Date())!, totalMinutes: 450, productiveMinutes: 280),
            DailyChartPoint(date: Calendar.current.date(byAdding: .day, value: -2, to: Date())!, totalMinutes: 380, productiveMinutes: 200),
            DailyChartPoint(date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!, totalMinutes: 340, productiveMinutes: 190),
            DailyChartPoint(date: Date(), totalMinutes: 385, productiveMinutes: 240)
        ]

        vm.categoryBreakdown = [
            CategoryBreakdownItem(name: "Deep Work", minutes: 180, color: Theme.primary),
            CategoryBreakdownItem(name: "Meetings", minutes: 90, color: Theme.accent),
            CategoryBreakdownItem(name: "Email", minutes: 60, color: Theme.warning),
            CategoryBreakdownItem(name: "Other", minutes: 55, color: .secondary)
        ]

        return vm
    }
}

import SwiftUI
