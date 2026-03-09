//
//  Goal.swift
//  DayArc
//
//  Created by Claude Code on 2/6/26.
//

import Foundation
import SwiftData

@Model
final class Goal {
    // MARK: - Core Properties
    var id: UUID
    var title: String
    var goalDescription: String
    var colorHex: String
    var status: GoalStatus
    var createdAt: Date
    var updatedAt: Date

    // MARK: - Timeline
    var startDate: Date
    var targetDate: Date?

    // MARK: - Progress
    var progress: Double // 0.0 to 1.0
    var milestones: Int
    var completedMilestones: Int

    // MARK: - Optional Properties
    var imageData: Data?
    var icon: String?

    // MARK: - Relationships
    @Relationship(deleteRule: .cascade, inverse: \GoalComment.goal)
    var comments: [GoalComment]?

    @Relationship(deleteRule: .nullify)
    var tags: [Tag]?

    // MARK: - Computed Properties
    var daysRemaining: Int? {
        guard let targetDate = targetDate else { return nil }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: targetDate)
        return components.day
    }

    var isOverdue: Bool {
        guard let targetDate = targetDate else { return false }
        return Date() > targetDate && status != .completed
    }

    var progressPercentage: Int {
        Int(progress * 100)
    }

    var sortedComments: [GoalComment] {
        (comments ?? []).sorted { $0.createdAt > $1.createdAt }
    }

    // MARK: - Initializer
    init(
        id: UUID = UUID(),
        title: String,
        goalDescription: String = "",
        colorHex: String = "#5856D6",
        status: GoalStatus = .notStarted,
        startDate: Date = Date(),
        targetDate: Date? = nil,
        progress: Double = 0.0,
        milestones: Int = 0,
        completedMilestones: Int = 0,
        imageData: Data? = nil,
        icon: String? = nil,
        tags: [Tag]? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.goalDescription = goalDescription
        self.colorHex = colorHex
        self.status = status
        self.startDate = startDate
        self.targetDate = targetDate
        self.progress = progress
        self.milestones = milestones
        self.completedMilestones = completedMilestones
        self.imageData = imageData
        self.icon = icon
        self.tags = tags
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Goal Status
enum GoalStatus: Int, Codable, CaseIterable {
    case notStarted = 0
    case inProgress = 1
    case onHold = 2
    case completed = 3
    case cancelled = 4

    var title: String {
        switch self {
        case .notStarted: return "Not Started"
        case .inProgress: return "In Progress"
        case .onHold: return "On Hold"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        }
    }

    var icon: String {
        switch self {
        case .notStarted: return "circle"
        case .inProgress: return "circle.lefthalf.filled"
        case .onHold: return "pause.circle"
        case .completed: return "checkmark.circle.fill"
        case .cancelled: return "xmark.circle"
        }
    }

    var colorHex: String {
        switch self {
        case .notStarted: return "#8E8E93"
        case .inProgress: return "#007AFF"
        case .onHold: return "#FF9500"
        case .completed: return "#34C759"
        case .cancelled: return "#FF3B30"
        }
    }
}

// MARK: - Formatting Helpers
extension Goal {
    var formattedTargetDate: String {
        guard let targetDate = targetDate else { return "No deadline" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: targetDate)
    }

    var formattedStartDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: startDate)
    }

    var timelineDescription: String {
        if let daysRemaining = daysRemaining {
            if daysRemaining < 0 {
                return "\(abs(daysRemaining)) days overdue"
            } else if daysRemaining == 0 {
                return "Due today"
            } else if daysRemaining == 1 {
                return "1 day remaining"
            } else {
                return "\(daysRemaining) days remaining"
            }
        }
        return "No deadline set"
    }
}
