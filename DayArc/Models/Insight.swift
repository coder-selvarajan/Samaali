//
//  Insight.swift
//  DayArc
//
//  Created by Claude Code on 2/6/26.
//

import Foundation
import SwiftUI

/// Represents an AI-generated insight about user's activity patterns
struct Insight: Identifiable, Equatable {
    let id: UUID
    let type: InsightType
    let title: String
    let message: String
    let priority: InsightPriority
    let relatedDate: Date?
    let createdAt: Date

    init(
        id: UUID = UUID(),
        type: InsightType,
        title: String,
        message: String,
        priority: InsightPriority,
        relatedDate: Date? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.message = message
        self.priority = priority
        self.relatedDate = relatedDate
        self.createdAt = createdAt
    }
}

// MARK: - Insight Type

enum InsightType: String, CaseIterable, Codable {
    case achievement = "Achievement"
    case pattern = "Pattern"
    case trend = "Trend"
    case recommendation = "Recommendation"
    case tip = "Tip"
    case warning = "Warning"

    var icon: String {
        switch self {
        case .achievement: return "trophy.fill"
        case .pattern: return "waveform.path.ecg"
        case .trend: return "chart.line.uptrend.xyaxis"
        case .recommendation: return "lightbulb.fill"
        case .tip: return "sparkles"
        case .warning: return "exclamationmark.triangle.fill"
        }
    }

    var color: Color {
        switch self {
        case .achievement: return .yellow
        case .pattern: return .purple
        case .trend: return .blue
        case .recommendation: return .orange
        case .tip: return .green
        case .warning: return .red
        }
    }

    var backgroundColor: Color {
        color.opacity(0.15)
    }
}

// MARK: - Insight Priority

enum InsightPriority: Int, Comparable, CaseIterable, Codable {
    case low = 0
    case medium = 1
    case high = 2

    static func < (lhs: InsightPriority, rhs: InsightPriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var title: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        }
    }
}

// MARK: - Weekly Summary

struct WeeklySummary: Identifiable {
    let id = UUID()
    let weekStartDate: Date
    let totalTrackedMinutes: Int
    let productiveMinutes: Int
    let activeDays: Int
    let topCategory: String?
    let averageProductivityScore: Double
    let pomodoroSessions: Int
    let insights: [Insight]

    var formattedTotalTime: String {
        let hours = totalTrackedMinutes / 60
        let minutes = totalTrackedMinutes % 60
        return "\(hours)h \(minutes)m"
    }

    var formattedProductiveTime: String {
        let hours = productiveMinutes / 60
        let minutes = productiveMinutes % 60
        return "\(hours)h \(minutes)m"
    }

    var productivityPercentage: Double {
        guard totalTrackedMinutes > 0 else { return 0 }
        return Double(productiveMinutes) / Double(totalTrackedMinutes)
    }

    var weekRangeLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let start = formatter.string(from: weekStartDate)
        guard let endDate = Calendar.current.date(byAdding: .day, value: 6, to: weekStartDate) else {
            return start
        }
        let end = formatter.string(from: endDate)
        return "\(start) - \(end)"
    }
}

// MARK: - Daily Insight Summary

struct DailyInsightSummary: Identifiable {
    let id = UUID()
    let date: Date
    let productivityScore: Double
    let dominantSentiment: SentimentLabel
    let trackedMinutes: Int
    let highlights: [String]

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: date)
    }

    var productivityLabel: String {
        switch productivityScore {
        case 0..<0.3: return "Low"
        case 0.3..<0.6: return "Moderate"
        case 0.6..<0.8: return "Good"
        default: return "Excellent"
        }
    }

    var productivityColor: Color {
        switch productivityScore {
        case 0..<0.3: return .red
        case 0.3..<0.6: return .orange
        case 0.6..<0.8: return .blue
        default: return .green
        }
    }
}

// MARK: - Productivity Trend

struct ProductivityTrend: Identifiable {
    let id = UUID()
    let date: Date
    let score: Double
    let trackedMinutes: Int

    var dayLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
}

// MARK: - Preview Helpers

extension Insight {
    static let previewInsights: [Insight] = [
        Insight(
            type: .achievement,
            title: "5-Day Streak!",
            message: "You've tracked activities for 5 consecutive days. Keep building the habit!",
            priority: .high,
            relatedDate: Date()
        ),
        Insight(
            type: .pattern,
            title: "Peak Productivity Hours",
            message: "Your most productive hours are 9AM-11AM. Consider scheduling important work during this window.",
            priority: .medium
        ),
        Insight(
            type: .trend,
            title: "Weekly Progress",
            message: "You logged 2 more hours this week compared to last week. Great improvement!",
            priority: .medium
        ),
        Insight(
            type: .recommendation,
            title: "Try Pomodoro",
            message: "Based on your patterns, the Pomodoro technique might help you maintain focus during longer tasks.",
            priority: .low
        ),
        Insight(
            type: .tip,
            title: "Add Notes",
            message: "Activities with notes provide better insights. Try adding context to your entries.",
            priority: .low
        )
    ]
}

extension WeeklySummary {
    static let preview = WeeklySummary(
        weekStartDate: Calendar.current.date(byAdding: .day, value: -6, to: Date())!,
        totalTrackedMinutes: 1840,
        productiveMinutes: 1200,
        activeDays: 6,
        topCategory: "Work",
        averageProductivityScore: 0.72,
        pomodoroSessions: 15,
        insights: Array(Insight.previewInsights.prefix(3))
    )
}
