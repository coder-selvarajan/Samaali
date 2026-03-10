//
//  Tag.swift
//  Samaali
//
//  Created by Claude Code on 2/2/26.
//

import Foundation
import SwiftData

@Model
final class Tag {
    var id: UUID
    var name: String
    var colorHex: String
    var icon: String?
    var isSystem: Bool
    var createdAt: Date

    @Relationship(deleteRule: .nullify)
    var activities: [Activity]?

    init(
        id: UUID = UUID(),
        name: String,
        colorHex: String = "#007AFF",
        icon: String? = nil,
        isSystem: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.icon = icon
        self.isSystem = isSystem
        self.createdAt = createdAt
    }
}

// MARK: - Default System Tags
extension Tag {
    static let systemTags: [(name: String, colorHex: String, icon: String)] = [
        ("Productive", "#34C759", "bolt.fill"),
        ("Non-Productive", "#FF9500", "moon.fill"),
        ("Entertainment", "#FF2D55", "play.fill"),
        ("Learning", "#5856D6", "book.fill"),
        ("Household", "#00C7BE", "house.fill"),
        ("Travel", "#007AFF", "car.fill"),
        ("Family", "#FF6482", "heart.fill"),
        ("Social", "#AF52DE", "person.2.fill"),
        ("Health", "#30D158", "figure.run"),
        ("Work", "#0A84FF", "briefcase.fill")
    ]
}
