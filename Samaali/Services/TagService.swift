//
//  TagService.swift
//  Samaali
//
//  Created by Claude Code on 2/2/26.
//

import Foundation
import SwiftData

/// Service for managing tags
@MainActor
final class TagService {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - CRUD Operations

    func createTag(
        name: String,
        colorHex: String = "#007AFF",
        icon: String? = nil,
        isSystem: Bool = false
    ) -> Tag {
        let tag = Tag(
            name: name,
            colorHex: colorHex,
            icon: icon,
            isSystem: isSystem
        )
        modelContext.insert(tag)
        return tag
    }

    func deleteTag(_ tag: Tag) {
        guard !tag.isSystem else { return } // Don't delete system tags
        modelContext.delete(tag)
    }

    // MARK: - Queries

    func fetchAllTags() throws -> [Tag] {
        let descriptor = FetchDescriptor<Tag>(
            sortBy: [SortDescriptor(\.name)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchSystemTags() throws -> [Tag] {
        let descriptor = FetchDescriptor<Tag>(
            predicate: #Predicate { tag in
                tag.isSystem == true
            },
            sortBy: [SortDescriptor(\.name)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchCustomTags() throws -> [Tag] {
        let descriptor = FetchDescriptor<Tag>(
            predicate: #Predicate { tag in
                tag.isSystem == false
            },
            sortBy: [SortDescriptor(\.name)]
        )
        return try modelContext.fetch(descriptor)
    }

    func findTag(byName name: String) throws -> Tag? {
        let descriptor = FetchDescriptor<Tag>(
            predicate: #Predicate { tag in
                tag.name == name
            }
        )
        return try modelContext.fetch(descriptor).first
    }

    // MARK: - Initialization

    func initializeSystemTagsIfNeeded() throws {
        let existingTags = try fetchSystemTags()

        guard existingTags.isEmpty else { return }

        for tagInfo in Tag.systemTags {
            _ = createTag(
                name: tagInfo.name,
                colorHex: tagInfo.colorHex,
                icon: tagInfo.icon,
                isSystem: true
            )
        }
    }
}
