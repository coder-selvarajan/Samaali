//
//  AIInsightsViewModel.swift
//  DayArc
//
//  Created by Claude Code on 2/6/26.
//

import Foundation
import SwiftData
import SwiftUI

/// ViewModel for AI Insights features
@MainActor
@Observable
final class AIInsightsViewModel {
    // MARK: - Published State

    var insights: [Insight] = []
    var weeklySummary: WeeklySummary?
    var productivityTrend: [ProductivityTrend] = []
    var streakInfo: StreakInfo?

    var isLoading = false
    var isAnalyzing = false
    var error: Error?
    var showError = false

    var lastRefreshDate: Date?
    var analyzedCount = 0

    // Settings
    var isEnabled: Bool {
        get { settingsService.enableAIInsights }
        set { settingsService.enableAIInsights = newValue }
    }

    // MARK: - Dependencies

    private let insightsService: AIInsightsService
    private let modelContext: ModelContext
    private let settingsService = SettingsService()

    // MARK: - Initialization

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.insightsService = AIInsightsService(modelContext: modelContext)
    }

    // MARK: - Data Loading

    func loadInsights() async {
        guard isEnabled else {
            insights = []
            return
        }

        isLoading = true
        error = nil

        do {
            insights = try await insightsService.generateInsights()
            lastRefreshDate = Date()
        } catch {
            self.error = error
            showError = true
        }

        isLoading = false
    }

    func loadWeeklySummary() async {
        isLoading = true

        do {
            let activities = try fetchActivitiesForWeek()

            let totalMinutes = activities.compactMap { $0.durationInMinutes }.reduce(0, +)
            let productiveMinutes = activities
                .filter { ($0.productivityScore ?? 0) >= 0.6 }
                .compactMap { $0.durationInMinutes }
                .reduce(0, +)

            let calendar = Calendar.current
            let activeDays = Set(activities.map { calendar.startOfDay(for: $0.startTime) }).count

            // Find top category
            var categoryCount: [String: Int] = [:]
            for activity in activities {
                if let tags = activity.tags {
                    for tag in tags {
                        categoryCount[tag.name, default: 0] += activity.durationInMinutes ?? 0
                    }
                }
            }
            let topCategory = categoryCount.max(by: { $0.value < $1.value })?.key

            // Calculate average productivity
            let scores = activities.compactMap { $0.productivityScore }
            let avgScore = scores.isEmpty ? 0 : scores.reduce(0, +) / Double(scores.count)

            // Count pomodoro sessions
            let pomodoroCount = activities.filter { $0.source == .pomodoro }.count

            weeklySummary = WeeklySummary(
                weekStartDate: calendar.date(byAdding: .day, value: -6, to: Date()) ?? Date(),
                totalTrackedMinutes: totalMinutes,
                productiveMinutes: productiveMinutes,
                activeDays: activeDays,
                topCategory: topCategory,
                averageProductivityScore: avgScore,
                pomodoroSessions: pomodoroCount,
                insights: Array(insights.prefix(3))
            )
        } catch {
            self.error = error
        }

        isLoading = false
    }

    func loadProductivityTrend() async {
        let calendar = Calendar.current

        do {
            let activities = try fetchActivitiesForWeek()

            // Group by day
            var dailyData: [Date: (scores: [Double], minutes: Int)] = [:]

            for activity in activities {
                let day = calendar.startOfDay(for: activity.startTime)
                var current = dailyData[day] ?? ([], 0)
                if let score = activity.productivityScore {
                    current.scores.append(score)
                }
                current.minutes += activity.durationInMinutes ?? 0
                dailyData[day] = current
            }

            // Create trend data for last 7 days
            productivityTrend = (0..<7).compactMap { daysAgo in
                guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: Date()) else { return nil }
                let day = calendar.startOfDay(for: date)
                let data = dailyData[day]
                let avgScore = data?.scores.isEmpty == false
                    ? data!.scores.reduce(0, +) / Double(data!.scores.count)
                    : 0

                return ProductivityTrend(
                    date: day,
                    score: avgScore,
                    trackedMinutes: data?.minutes ?? 0
                )
            }.reversed()

        } catch {
            self.error = error
        }
    }

    func loadStreakInfo() async {
        do {
            let activities = try fetchRecentActivities(days: 90)
            streakInfo = insightsService.detectStreaks(from: activities)
        } catch {
            self.error = error
        }
    }

    // MARK: - Analysis Actions

    func analyzeAllActivities() async {
        isAnalyzing = true
        error = nil

        do {
            analyzedCount = try await insightsService.analyzeUnreviewedActivities()
            await loadInsights()
        } catch {
            self.error = error
            showError = true
        }

        isAnalyzing = false
    }

    func refreshAll() async {
        await loadInsights()
        await loadWeeklySummary()
        await loadProductivityTrend()
        await loadStreakInfo()
    }

    // MARK: - Computed Properties

    var topInsight: Insight? {
        insights.first
    }

    var hasInsights: Bool {
        !insights.isEmpty
    }

    var formattedLastRefresh: String? {
        guard let date = lastRefreshDate else { return nil }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    var currentStreakLabel: String {
        guard let streak = streakInfo else { return "0 days" }
        return streak.currentStreak == 1 ? "1 day" : "\(streak.currentStreak) days"
    }

    var averageProductivityLabel: String {
        guard let summary = weeklySummary else { return "N/A" }
        return "\(Int(summary.averageProductivityScore * 100))%"
    }

    // MARK: - Private Helpers

    private func fetchActivitiesForWeek() throws -> [Activity] {
        let calendar = Calendar.current
        guard let startDate = calendar.date(byAdding: .day, value: -7, to: Date()) else {
            return []
        }

        let descriptor = FetchDescriptor<Activity>(
            predicate: #Predicate { activity in
                activity.startTime >= startDate
            },
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )

        return try modelContext.fetch(descriptor)
    }

    private func fetchRecentActivities(days: Int) throws -> [Activity] {
        let calendar = Calendar.current
        guard let startDate = calendar.date(byAdding: .day, value: -days, to: Date()) else {
            return []
        }

        let descriptor = FetchDescriptor<Activity>(
            predicate: #Predicate { activity in
                activity.startTime >= startDate
            },
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )

        return try modelContext.fetch(descriptor)
    }
}

// MARK: - Preview Helper

extension AIInsightsViewModel {
    static func preview(modelContext: ModelContext) -> AIInsightsViewModel {
        let vm = AIInsightsViewModel(modelContext: modelContext)
        vm.insights = Insight.previewInsights
        vm.weeklySummary = WeeklySummary.preview
        vm.streakInfo = StreakInfo(currentStreak: 5, longestStreak: 12, totalDaysTracked: 45)
        vm.productivityTrend = (0..<7).map { i in
            let date = Calendar.current.date(byAdding: .day, value: -i, to: Date())!
            return ProductivityTrend(
                date: date,
                score: Double.random(in: 0.4...0.9),
                trackedMinutes: Int.random(in: 120...480)
            )
        }.reversed()
        return vm
    }
}
