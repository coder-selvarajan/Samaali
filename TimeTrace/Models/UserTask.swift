//
//  UserTask.swift
//  TimeTrace
//
//  Created by Claude Code on 2/2/26.
//

import Foundation
import SwiftData

@Model
final class UserTask {
    var id: UUID
    var title: String
    var notes: String?
    var isCompleted: Bool
    var dueDate: Date?
    var reminderDate: Date?
    var priority: TaskPriority
    var createdAt: Date
    var completedAt: Date?

    var tags: [Tag]?

    var linkedActivity: Activity?

    init(
        id: UUID = UUID(),
        title: String,
        notes: String? = nil,
        isCompleted: Bool = false,
        dueDate: Date? = nil,
        reminderDate: Date? = nil,
        priority: TaskPriority = .medium,
        tags: [Tag]? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.isCompleted = isCompleted
        self.dueDate = dueDate
        self.reminderDate = reminderDate
        self.priority = priority
        self.tags = tags
        self.createdAt = createdAt
    }
}

// MARK: - Task Priority
enum TaskPriority: Int, Codable, CaseIterable {
    case low = 0
    case medium = 1
    case high = 2

    var title: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        }
    }

    var icon: String {
        switch self {
        case .low: return "arrow.down"
        case .medium: return "minus"
        case .high: return "arrow.up"
        }
    }

    var colorName: String {
        switch self {
        case .low: return "blue"
        case .medium: return "orange"
        case .high: return "red"
        }
    }
}
