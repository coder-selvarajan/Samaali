//
//  AIInsightsService.swift
//  DayArc
//
//  Created by Claude Code on 2/6/26.
//

import Foundation
import SwiftData
import NaturalLanguage

/// On-Device AI Service for generating activity insights
///
/// ## Privacy Considerations:
/// - All processing happens locally on-device
/// - No data is sent to external servers
/// - Uses Apple's NaturalLanguage framework
/// - User can disable AI features in settings
///
/// ## Capabilities:
/// - Sentiment analysis of activity notes
/// - Productivity scoring based on patterns
/// - Pattern detection (peak hours, trends)
/// - Category suggestions using NLP
/// - Weekly/monthly summaries
@MainActor
final class AIInsightsService {
    private let modelContext: ModelContext
    private let sentimentTagger: NLTagger
    private let tokenizer: NLTokenizer

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.sentimentTagger = NLTagger(tagSchemes: [.sentimentScore])
        self.tokenizer = NLTokenizer(unit: .word)
    }

    // MARK: - Insight Generation

    /// Generate all insights for the user
    func generateInsights() async throws -> [Insight] {
        let activities = try fetchRecentActivities(days: 30)

        guard activities.count >= AppConstants.AIInsights.minimumActivitiesForInsights else {
            return [Insight(
                type: .tip,
                title: "Keep Tracking",
                message: "Log more activities to unlock personalized insights. You need at least \(AppConstants.AIInsights.minimumActivitiesForInsights) activities.",
                priority: .low,
                relatedDate: Date()
            )]
        }

        var insights: [Insight] = []

        // Generate various insight types
        insights.append(contentsOf: generateProductivityInsights(from: activities))
        insights.append(contentsOf: generatePatternInsights(from: activities))
        insights.append(contentsOf: generateTrendInsights(from: activities))
        insights.append(contentsOf: generateRecommendations(from: activities))

        // Sort by priority and limit
        return insights
            .sorted { $0.priority.rawValue > $1.priority.rawValue }
            .prefix(AppConstants.AIInsights.maxInsightsToShow)
            .map { $0 }
    }

    // MARK: - Sentiment Analysis

    /// Analyze sentiment of activity notes
    func analyzeSentiment(text: String) -> SentimentResult {
        guard !text.isEmpty else {
            return SentimentResult(score: 0, label: .neutral)
        }

        sentimentTagger.string = text
        let range = text.startIndex..<text.endIndex

        var totalScore: Double = 0
        var count = 0

        sentimentTagger.enumerateTags(in: range, unit: .paragraph, scheme: .sentimentScore) { tag, _ in
            if let tag = tag, let score = Double(tag.rawValue) {
                totalScore += score
                count += 1
            }
            return true
        }

        let averageScore = count > 0 ? totalScore / Double(count) : 0

        let label: SentimentLabel
        switch averageScore {
        case 0.1...: label = .positive
        case ..<(-0.1): label = .negative
        default: label = .neutral
        }

        return SentimentResult(score: averageScore, label: label)
    }

    /// Update sentiment for an activity
    func updateActivitySentiment(_ activity: Activity) {
        guard let notes = activity.notes, !notes.isEmpty else { return }

        let result = analyzeSentiment(text: notes)
        activity.sentiment = result.label.rawValue
    }

    // MARK: - Productivity Scoring

    /// Calculate productivity score for an activity
    func calculateProductivityScore(for activity: Activity) -> Double {
        var score: Double = 0.5 // Base neutral score

        // Factor 1: Time of day bonus (morning productivity)
        let hour = Calendar.current.component(.hour, from: activity.startTime)
        if (6...11).contains(hour) {
            score += 0.1 // Morning bonus
        } else if (22...23).contains(hour) || (0...5).contains(hour) {
            score -= 0.1 // Late night penalty
        }

        // Factor 2: Duration bonus (focused work)
        if let duration = activity.durationInMinutes {
            if duration >= 25 && duration <= 90 {
                score += 0.15 // Optimal focus duration
            } else if duration > 180 {
                score -= 0.05 // Very long sessions may indicate lack of breaks
            }
        }

        // Factor 3: Tag-based scoring
        if let tags = activity.tags {
            for tag in tags {
                score += productivityModifier(for: tag.name)
            }
        }

        // Factor 4: Notes sentiment
        if let notes = activity.notes, !notes.isEmpty {
            let sentiment = analyzeSentiment(text: notes)
            score += sentiment.score * 0.1 // Slight adjustment based on sentiment
        }

        // Factor 5: Source bonus
        switch activity.source {
        case .pomodoro:
            score += 0.15 // Structured work bonus
        case .screenTime:
            score -= 0.05 // Passive tracking slight penalty
        default:
            break
        }

        return max(0, min(1, score)) // Clamp to 0-1
    }

    /// Update productivity score for an activity
    func updateActivityProductivity(_ activity: Activity) {
        activity.productivityScore = calculateProductivityScore(for: activity)
    }

    // MARK: - Pattern Detection

    /// Detect most productive hours
    func detectPeakProductivityHours(from activities: [Activity]) -> [Int] {
        var hourlyProductivity: [Int: (total: Double, count: Int)] = [:]

        for activity in activities {
            let hour = Calendar.current.component(.hour, from: activity.startTime)
            let score = activity.productivityScore ?? 0.5

            let current = hourlyProductivity[hour] ?? (0, 0)
            hourlyProductivity[hour] = (current.total + score, current.count + 1)
        }

        let averages = hourlyProductivity.map { hour, data in
            (hour: hour, average: data.total / Double(data.count))
        }

        return averages
            .sorted { $0.average > $1.average }
            .prefix(3)
            .map { $0.hour }
    }

    /// Detect most productive days of week
    func detectPeakProductivityDays(from activities: [Activity]) -> [Int] {
        var dailyProductivity: [Int: (total: Double, count: Int)] = [:]

        for activity in activities {
            let weekday = Calendar.current.component(.weekday, from: activity.startTime)
            let score = activity.productivityScore ?? 0.5

            let current = dailyProductivity[weekday] ?? (0, 0)
            dailyProductivity[weekday] = (current.total + score, current.count + 1)
        }

        let averages = dailyProductivity.map { day, data in
            (day: day, average: data.total / Double(data.count))
        }

        return averages
            .sorted { $0.average > $1.average }
            .prefix(2)
            .map { $0.day }
    }

    /// Detect activity streaks
    func detectStreaks(from activities: [Activity]) -> StreakInfo {
        let calendar = Calendar.current
        let today = Date()

        // Group activities by day
        var daySet: Set<Date> = []
        for activity in activities {
            let dayStart = calendar.startOfDay(for: activity.startTime)
            daySet.insert(dayStart)
        }

        // Calculate current streak
        var currentStreak = 0
        var checkDate = calendar.startOfDay(for: today)

        while daySet.contains(checkDate) {
            currentStreak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = previousDay
        }

        // Calculate longest streak (simplified)
        let sortedDays = daySet.sorted()
        var longestStreak = sortedDays.isEmpty ? 0 : 1
        var tempStreak = 1

        if sortedDays.count > 1 {
            for i in 1..<sortedDays.count {
                let diff = calendar.dateComponents([.day], from: sortedDays[i-1], to: sortedDays[i]).day ?? 0
                if diff == 1 {
                    tempStreak += 1
                } else {
                    longestStreak = max(longestStreak, tempStreak)
                    tempStreak = 1
                }
            }
            longestStreak = max(longestStreak, tempStreak)
        }

        return StreakInfo(
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            totalDaysTracked: daySet.count
        )
    }

    // MARK: - Category Suggestions

    /// Suggest a category for activity based on title and notes
    func suggestCategory(title: String, notes: String?) -> String? {
        let text = [title, notes].compactMap { $0 }.joined(separator: " ").lowercased()

        // Keyword-based categorization
        let categories: [(keywords: [String], category: String)] = [
            (["meeting", "call", "zoom", "teams", "standup", "sync"], "Work"),
            (["code", "coding", "programming", "debug", "develop"], "Productive"),
            (["email", "mail", "inbox", "reply"], "Communication"),
            (["exercise", "workout", "run", "gym", "yoga", "walk"], "Health"),
            (["read", "study", "learn", "course", "tutorial"], "Learning"),
            (["cook", "clean", "laundry", "dishes", "chores"], "Household"),
            (["netflix", "youtube", "game", "tv", "movie", "show"], "Entertainment"),
            (["social", "friend", "family", "dinner", "lunch"], "Social"),
            (["travel", "commute", "drive", "flight", "train"], "Travel"),
            (["break", "rest", "nap", "relax", "meditation"], "Rest")
        ]

        for (keywords, category) in categories {
            if keywords.contains(where: { text.contains($0) }) {
                return category
            }
        }

        return nil
    }

    /// Update suggested category for an activity
    func updateActivityCategory(_ activity: Activity) {
        if let suggestion = suggestCategory(title: activity.title, notes: activity.notes) {
            activity.suggestedCategory = suggestion
        }
    }

    // MARK: - Bulk Analysis

    /// Analyze all unreviewed activities
    func analyzeUnreviewedActivities() async throws -> Int {
        let descriptor = FetchDescriptor<Activity>(
            predicate: #Predicate { activity in
                activity.aiInsightsReviewed == false
            }
        )

        let activities = try modelContext.fetch(descriptor)
        var analyzed = 0

        for activity in activities {
            updateActivitySentiment(activity)
            updateActivityProductivity(activity)
            updateActivityCategory(activity)
            activity.aiInsightsReviewed = true
            analyzed += 1
        }

        return analyzed
    }

    // MARK: - Private Helpers

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

    private func productivityModifier(for tagName: String) -> Double {
        let productive = ["Productive", "Work", "Learning", "Health", "Deep Work"]
        let neutral = ["Social", "Communication", "Travel", "Household"]
        let leisure = ["Entertainment", "Non-Productive", "Rest"]

        if productive.contains(tagName) { return 0.15 }
        if neutral.contains(tagName) { return 0 }
        if leisure.contains(tagName) { return -0.1 }
        return 0
    }

    // MARK: - Insight Generators

    private func generateProductivityInsights(from activities: [Activity]) -> [Insight] {
        var insights: [Insight] = []

        // Calculate average productivity
        let scores = activities.compactMap { $0.productivityScore }
        guard !scores.isEmpty else { return insights }

        let averageScore = scores.reduce(0, +) / Double(scores.count)

        // Today's productivity vs average
        let todayActivities = activities.filter { Calendar.current.isDateInToday($0.startTime) }
        let todayScores = todayActivities.compactMap { $0.productivityScore }
        let todayAverage = todayScores.isEmpty ? 0 : todayScores.reduce(0, +) / Double(todayScores.count)

        if todayAverage > averageScore + 0.1 {
            insights.append(Insight(
                type: .achievement,
                title: "Productive Day!",
                message: "You're \(Int((todayAverage - averageScore) * 100))% more productive than your average today. Keep it up!",
                priority: .medium,
                relatedDate: Date()
            ))
        } else if todayAverage < averageScore - 0.1 && !todayActivities.isEmpty {
            insights.append(Insight(
                type: .tip,
                title: "Room for Improvement",
                message: "Today's productivity is below your usual. Consider a short break or trying the Pomodoro timer.",
                priority: .low,
                relatedDate: Date()
            ))
        }

        return insights
    }

    private func generatePatternInsights(from activities: [Activity]) -> [Insight] {
        var insights: [Insight] = []

        // Peak hours insight
        let peakHours = detectPeakProductivityHours(from: activities)
        if !peakHours.isEmpty {
            let hourStrings = peakHours.map { hour in
                let formatter = DateFormatter()
                formatter.dateFormat = "ha"
                let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date())!
                return formatter.string(from: date)
            }

            insights.append(Insight(
                type: .pattern,
                title: "Peak Productivity Hours",
                message: "You're most productive around \(hourStrings.joined(separator: ", ")). Schedule important work during these times.",
                priority: .medium,
                relatedDate: nil
            ))
        }

        // Streak insight
        let streakInfo = detectStreaks(from: activities)
        if streakInfo.currentStreak >= 3 {
            insights.append(Insight(
                type: .achievement,
                title: "\(streakInfo.currentStreak)-Day Streak!",
                message: "You've tracked activities for \(streakInfo.currentStreak) days in a row. Your longest streak is \(streakInfo.longestStreak) days.",
                priority: streakInfo.currentStreak >= 7 ? .high : .medium,
                relatedDate: Date()
            ))
        }

        return insights
    }

    private func generateTrendInsights(from activities: [Activity]) -> [Insight] {
        var insights: [Insight] = []
        let calendar = Calendar.current

        // Week over week comparison
        let thisWeek = activities.filter {
            guard let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) else { return false }
            return $0.startTime >= weekAgo
        }

        let lastWeek = activities.filter {
            guard let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()),
                  let twoWeeksAgo = calendar.date(byAdding: .day, value: -14, to: Date()) else { return false }
            return $0.startTime >= twoWeeksAgo && $0.startTime < weekAgo
        }

        if !lastWeek.isEmpty {
            let thisWeekMinutes = thisWeek.compactMap { $0.durationInMinutes }.reduce(0, +)
            let lastWeekMinutes = lastWeek.compactMap { $0.durationInMinutes }.reduce(0, +)

            if thisWeekMinutes > lastWeekMinutes {
                let increase = thisWeekMinutes - lastWeekMinutes
                insights.append(Insight(
                    type: .trend,
                    title: "Increased Activity",
                    message: "You've logged \(increase / 60)h \(increase % 60)m more than last week. Great progress!",
                    priority: .low,
                    relatedDate: nil
                ))
            }
        }

        return insights
    }

    private func generateRecommendations(from activities: [Activity]) -> [Insight] {
        var insights: [Insight] = []

        // Check for missing breaks
        let longSessions = activities.filter {
            ($0.durationInMinutes ?? 0) > 120
        }

        if !longSessions.isEmpty && longSessions.count > 3 {
            insights.append(Insight(
                type: .recommendation,
                title: "Consider Regular Breaks",
                message: "You have several sessions over 2 hours. Try the Pomodoro technique for better focus and energy.",
                priority: .medium,
                relatedDate: nil
            ))
        }

        // Check for late-night activity
        let lateNightActivities = activities.filter {
            let hour = calendar.component(.hour, from: $0.startTime)
            return hour >= 22 || hour < 6
        }

        if lateNightActivities.count > 5 {
            insights.append(Insight(
                type: .recommendation,
                title: "Evening Wind-Down",
                message: "You've been active late at night frequently. Consider setting a daily wind-down time for better rest.",
                priority: .low,
                relatedDate: nil
            ))
        }

        return insights
    }

    private var calendar: Calendar { Calendar.current }
}

// MARK: - Supporting Models

struct SentimentResult {
    let score: Double
    let label: SentimentLabel
}

enum SentimentLabel: String {
    case positive = "positive"
    case neutral = "neutral"
    case negative = "negative"

    var icon: String {
        switch self {
        case .positive: return "face.smiling"
        case .neutral: return "face.dashed"
        case .negative: return "face.smiling.inverse"
        }
    }

    var color: String {
        switch self {
        case .positive: return "#34C759"
        case .neutral: return "#8E8E93"
        case .negative: return "#FF3B30"
        }
    }
}

struct StreakInfo {
    let currentStreak: Int
    let longestStreak: Int
    let totalDaysTracked: Int
}
