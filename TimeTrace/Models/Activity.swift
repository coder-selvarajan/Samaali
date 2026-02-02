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
    var id: UUID
    var title: String
    var notes: String?
    var startTime: Date
    var endTime: Date?
    var source: ActivitySource
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .nullify, inverse: \Tag.activities)
    var tags: [Tag]?

    // Computed duration in seconds
    var duration: TimeInterval? {
        guard let endTime = endTime else { return nil }
        return endTime.timeIntervalSince(startTime)
    }

    var isOngoing: Bool {
        endTime == nil
    }

    init(
        id: UUID = UUID(),
        title: String,
        notes: String? = nil,
        startTime: Date = Date(),
        endTime: Date? = nil,
        source: ActivitySource = .manual,
        tags: [Tag]? = nil,
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
        self.createdAt = createdAt
        self.updatedAt = updatedAt
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
