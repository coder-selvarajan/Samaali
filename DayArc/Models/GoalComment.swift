//
//  GoalComment.swift
//  DayArc
//
//  Created by Claude Code on 2/6/26.
//

import Foundation
import SwiftData

@Model
final class GoalComment {
    // MARK: - Properties
    var id: UUID
    var content: String
    var createdAt: Date

    // MARK: - Relationship
    var goal: Goal?

    // MARK: - Initializer
    init(
        id: UUID = UUID(),
        content: String,
        goal: Goal? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.content = content
        self.goal = goal
        self.createdAt = createdAt
    }
}

// MARK: - Formatting Helpers
extension GoalComment {
    var formattedDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }

    var formattedFullDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: createdAt)
    }
}
