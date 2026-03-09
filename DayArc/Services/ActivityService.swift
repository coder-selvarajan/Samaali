//
//  ActivityService.swift
//  DayArc
//
//  Created by Claude Code on 2/2/26.
//

import Foundation
import SwiftData

/// Service for managing activity data operations
@MainActor
final class ActivityService {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - CRUD Operations

    func createActivity(
        title: String,
        notes: String? = nil,
        startTime: Date = Date(),
        endTime: Date? = nil,
        source: ActivitySource = .manual,
        tags: [Tag]? = nil
    ) -> Activity {
        let activity = Activity(
            title: title,
            notes: notes,
            startTime: startTime,
            endTime: endTime,
            source: source,
            tags: tags
        )
        modelContext.insert(activity)
        return activity
    }

    func deleteActivity(_ activity: Activity) {
        modelContext.delete(activity)
    }

    func endActivity(_ activity: Activity, at endTime: Date = Date()) {
        activity.endTime = endTime
        activity.updatedAt = Date()
    }

    // MARK: - Queries

    func fetchActivities(for date: Date) throws -> [Activity] {
        let startOfDay = date.startOfDay
        let endOfDay = date.endOfDay

        let descriptor = FetchDescriptor<Activity>(
            predicate: #Predicate { activity in
                activity.startTime >= startOfDay && activity.startTime <= endOfDay
            },
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )

        return try modelContext.fetch(descriptor)
    }

    func fetchActivities(from startDate: Date, to endDate: Date) throws -> [Activity] {
        let descriptor = FetchDescriptor<Activity>(
            predicate: #Predicate { activity in
                activity.startTime >= startDate && activity.startTime <= endDate
            },
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )

        return try modelContext.fetch(descriptor)
    }

    func fetchMostRecentActivity() throws -> Activity? {
        var descriptor = FetchDescriptor<Activity>(
            sortBy: [SortDescriptor(\.endTime, order: .reverse)]
        )
        descriptor.fetchLimit = 1

        return try modelContext.fetch(descriptor).first
    }

    func fetchOngoingActivities() throws -> [Activity] {
        let descriptor = FetchDescriptor<Activity>(
            predicate: #Predicate { activity in
                activity.endTime == nil
            },
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )

        return try modelContext.fetch(descriptor)
    }

    // MARK: - Analytics

    func totalDuration(for date: Date) throws -> TimeInterval {
        let activities = try fetchActivities(for: date)
        return activities.compactMap(\.duration).reduce(0, +)
    }

    func totalDuration(for date: Date, withTag tag: Tag) throws -> TimeInterval {
        let activities = try fetchActivities(for: date)
        return activities
            .filter { $0.tags?.contains(where: { $0.id == tag.id }) ?? false }
            .compactMap(\.duration)
            .reduce(0, +)
    }

    // MARK: - Gap Detection

    func minutesSinceLastActivity() throws -> Int? {
        guard let lastActivity = try fetchMostRecentActivity(),
              let endTime = lastActivity.endTime else {
            return nil
        }
        return Date().minutesSince(endTime)
    }

    func shouldPromptForActivity(threshold: Int) throws -> Bool {
        guard let minutes = try minutesSinceLastActivity() else {
            return true // No activities yet, prompt user
        }
        return minutes >= threshold
    }
}
