//
//  Activity.swift
//  TimeTrace
//
//  Created by Claude Code on 2/2/26.
//

import Foundation
import SwiftData

@Model
final class Activity {
    // MARK: - Core Properties
    var id: UUID
    var title: String
    var notes: String?
    var startTime: Date
    var endTime: Date?
    var source: ActivitySource
    var createdAt: Date
    var updatedAt: Date

    // MARK: - Relationships
    @Relationship(deleteRule: .nullify)
    var tags: [Tag]?

    // MARK: - AI Insights (Prompt B Extension)
    /// Productivity score from 0.0 to 1.0, set by AI analysis
    var productivityScore: Double?

    /// Sentiment analysis result: positive, negative, or neutral
    var sentiment: String?

    /// AI-suggested category for this activity
    var suggestedCategory: String?

    /// Whether the user has reviewed/confirmed AI suggestions
    var aiInsightsReviewed: Bool

    // MARK: - Optional Metadata
    /// User's energy level at the time (1-5 scale)
    var energyLevel: Int?

    /// User's mood at the time (1-5 scale)
    var moodLevel: Int?

    /// Location context (e.g., "Home", "Office", "Commute")
    var locationContext: String?

    /// Associated app bundle identifier (for screen time activities)
    var appBundleId: String?

    // MARK: - Computed Properties
    var duration: TimeInterval? {
        guard let endTime = endTime else { return nil }
        return endTime.timeIntervalSince(startTime)
    }

    var isOngoing: Bool {
        endTime == nil
    }

    var durationInMinutes: Int? {
        guard let duration = duration else { return nil }
        return Int(duration / 60)
    }

    var productivityCategory: ProductivityCategory {
        guard let score = productivityScore else { return .unrated }
        switch score {
        case 0..<0.3: return .low
        case 0.3..<0.7: return .medium
        default: return .high
        }
    }

    // MARK: - Initializer
    init(
        id: UUID = UUID(),
        title: String,
        notes: String? = nil,
        startTime: Date = Date(),
        endTime: Date? = nil,
        source: ActivitySource = .manual,
        tags: [Tag]? = nil,
        productivityScore: Double? = nil,
        sentiment: String? = nil,
        suggestedCategory: String? = nil,
        aiInsightsReviewed: Bool = false,
        energyLevel: Int? = nil,
        moodLevel: Int? = nil,
        locationContext: String? = nil,
        appBundleId: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.startTime = startTime
        self.endTime = endTime
        self.source = source
        self.tags = tags
        self.productivityScore = productivityScore
        self.sentiment = sentiment
        self.suggestedCategory = suggestedCategory
        self.aiInsightsReviewed = aiInsightsReviewed
        self.energyLevel = energyLevel
        self.moodLevel = moodLevel
        self.locationContext = locationContext
        self.appBundleId = appBundleId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Productivity Category
enum ProductivityCategory: String, CaseIterable {
    case unrated = "Unrated"
    case low = "Low"
    case medium = "Medium"
    case high = "High"

    var color: String {
        switch self {
        case .unrated: return "#8E8E93"
        case .low: return "#FF3B30"
        case .medium: return "#FF9500"
        case .high: return "#34C759"
        }
    }
}

// MARK: - Activity Source
enum ActivitySource: String, Codable, CaseIterable {
    case manual = "Manual"
    case pomodoro = "Pomodoro"
    case screenTime = "Screen Time"
    case aiSuggested = "AI Suggested"

    var icon: String {
        switch self {
        case .manual: return "hand.tap"
        case .pomodoro: return "timer"
        case .screenTime: return "iphone"
        case .aiSuggested: return "sparkles"
        }
    }
}

// MARK: - Formatting Helpers
extension Activity {
    var formattedDuration: String {
        guard let duration = duration else { return "Ongoing" }
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    var formattedTimeRange: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short

        let start = formatter.string(from: startTime)
        if let endTime = endTime {
            let end = formatter.string(from: endTime)
            return "\(start) – \(end)"
        }
        return "\(start) – now"
    }
}
