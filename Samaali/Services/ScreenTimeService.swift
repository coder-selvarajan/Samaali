//
//  ScreenTimeService.swift
//  Samaali
//
//  Created by Claude Code on 2/6/26.
//

import Foundation
import SwiftData
import DeviceActivity
import FamilyControls
import ManagedSettings

/// Service for integrating with Screen Time / Device Activity APIs
///
/// ## Important Limitations:
/// - Requires iOS 16+ for DeviceActivity framework
/// - User must authorize Family Controls access
/// - Apps can only access aggregated usage data, not detailed app logs
/// - DeviceActivityReport extension needed for custom UI reporting
/// - Some features require Family Sharing or parental control setup
///
/// ## Privacy Considerations:
/// - All data stays on-device
/// - User explicitly grants permission
/// - Only category-level data exported, not app-specific details by default
@MainActor
final class ScreenTimeService {
    private let modelContext: ModelContext
    private let authorizationCenter = AuthorizationCenter.shared

    // MARK: - Authorization Status

    enum AuthorizationStatus {
        case notDetermined
        case authorized
        case denied

        var description: String {
            switch self {
            case .notDetermined: return "Not Requested"
            case .authorized: return "Authorized"
            case .denied: return "Denied"
            }
        }
    }

    private(set) var authorizationStatus: AuthorizationStatus = .notDetermined

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        checkAuthorizationStatus()
    }

    // MARK: - Authorization

    /// Check current authorization status for Family Controls
    func checkAuthorizationStatus() {
        switch authorizationCenter.authorizationStatus {
        case .notDetermined:
            authorizationStatus = .notDetermined
        case .approved:
            authorizationStatus = .authorized
        case .denied:
            authorizationStatus = .denied
        @unknown default:
            authorizationStatus = .notDetermined
        }
    }

    /// Request authorization to access Screen Time data
    /// - Returns: Whether authorization was granted
    func requestAuthorization() async throws -> Bool {
        do {
            try await authorizationCenter.requestAuthorization(for: .individual)
            checkAuthorizationStatus()
            return authorizationStatus == .authorized
        } catch {
            print("Screen Time authorization failed: \(error)")
            checkAuthorizationStatus()
            throw ScreenTimeError.authorizationFailed(error)
        }
    }

    // MARK: - Device Activity Monitoring

    /// Start monitoring device activity for a schedule
    /// This allows the app to receive callbacks when usage thresholds are met
    func startMonitoring(schedule: DeviceActivitySchedule, events: [DeviceActivityEvent.Name: DeviceActivityEvent]) throws {
        guard authorizationStatus == .authorized else {
            throw ScreenTimeError.notAuthorized
        }

        let center = DeviceActivityCenter()
        try center.startMonitoring(.daily, during: schedule, events: events)
    }

    /// Stop monitoring device activity
    func stopMonitoring() {
        let center = DeviceActivityCenter()
        center.stopMonitoring([.daily])
    }

    // MARK: - Activity Import

    /// Import screen time summary as activities
    /// Note: Due to API limitations, this creates summarized activities by category
    func importScreenTimeSummary(_ summary: ScreenTimeSummary) throws -> [Activity] {
        var createdActivities: [Activity] = []

        for categoryUsage in summary.categoryUsages {
            guard categoryUsage.durationMinutes >= 5 else { continue } // Skip very short usage

            let activity = Activity(
                title: categoryUsage.categoryName,
                notes: "Imported from Screen Time",
                startTime: summary.date.startOfDay,
                endTime: summary.date.startOfDay.addingTimeInterval(Double(categoryUsage.durationMinutes) * 60),
                source: .screenTime,
                appBundleId: categoryUsage.topAppBundleId
            )

            // Set productivity score based on category
            activity.productivityScore = categoryUsage.category.defaultProductivityScore

            // Auto-tag based on category
            if let tag = findOrCreateTag(for: categoryUsage.category) {
                activity.tags = [tag]
            }

            modelContext.insert(activity)
            createdActivities.append(activity)
        }

        return createdActivities
    }

    /// Create activities from app usage data
    func createActivityFromAppUsage(
        appName: String,
        bundleId: String,
        startTime: Date,
        durationMinutes: Int,
        category: AppCategory
    ) -> Activity {
        let activity = Activity(
            title: "\(appName) Usage",
            startTime: startTime,
            endTime: startTime.addingTimeInterval(Double(durationMinutes) * 60),
            source: .screenTime,
            productivityScore: category.defaultProductivityScore,
            appBundleId: bundleId
        )

        if let tag = findOrCreateTag(for: category) {
            activity.tags = [tag]
        }

        modelContext.insert(activity)
        return activity
    }

    // MARK: - Tag Mapping

    /// Find or create a tag for an app category
    private func findOrCreateTag(for category: AppCategory) -> Tag? {
        let tagName = category.tagName

        // Try to find existing tag
        let descriptor = FetchDescriptor<Tag>(
            predicate: #Predicate { tag in
                tag.name == tagName
            }
        )

        do {
            let existingTags = try modelContext.fetch(descriptor)
            if let existing = existingTags.first {
                return existing
            }

            // Create new tag
            let newTag = Tag(
                name: tagName,
                colorHex: category.colorHex,
                icon: category.icon,
                isSystem: true
            )
            modelContext.insert(newTag)
            return newTag
        } catch {
            print("Failed to find/create tag: \(error)")
            return nil
        }
    }

    // MARK: - Schedule Helpers

    /// Create a daily monitoring schedule
    static func createDailySchedule() -> DeviceActivitySchedule {
        let calendar = Calendar.current

        // Monitor from 6 AM to midnight
        let intervalStart = DateComponents(hour: 6, minute: 0)
        let intervalEnd = DateComponents(hour: 23, minute: 59)

        return DeviceActivitySchedule(
            intervalStart: intervalStart,
            intervalEnd: intervalEnd,
            repeats: true
        )
    }
}

// MARK: - Screen Time Error

enum ScreenTimeError: LocalizedError {
    case notAuthorized
    case authorizationFailed(Error)
    case importFailed(Error)
    case monitoringFailed(Error)

    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Screen Time access not authorized. Please enable in Settings."
        case .authorizationFailed(let error):
            return "Authorization failed: \(error.localizedDescription)"
        case .importFailed(let error):
            return "Failed to import Screen Time data: \(error.localizedDescription)"
        case .monitoringFailed(let error):
            return "Failed to start monitoring: \(error.localizedDescription)"
        }
    }
}

// MARK: - App Category

/// Categories for screen time apps with productivity mapping
enum AppCategory: String, CaseIterable, Codable {
    case productivity = "Productivity"
    case social = "Social"
    case entertainment = "Entertainment"
    case games = "Games"
    case education = "Education"
    case health = "Health & Fitness"
    case news = "News"
    case utilities = "Utilities"
    case communication = "Communication"
    case creativity = "Creativity"
    case finance = "Finance"
    case travel = "Travel"
    case shopping = "Shopping"
    case other = "Other"

    /// Default productivity score for this category (0.0 - 1.0)
    var defaultProductivityScore: Double {
        switch self {
        case .productivity: return 0.9
        case .education: return 0.85
        case .health: return 0.8
        case .creativity: return 0.75
        case .finance: return 0.7
        case .utilities: return 0.6
        case .communication: return 0.5
        case .news: return 0.4
        case .travel: return 0.4
        case .shopping: return 0.3
        case .social: return 0.25
        case .entertainment: return 0.2
        case .games: return 0.15
        case .other: return 0.5
        }
    }

    /// Tag name for this category
    var tagName: String {
        switch self {
        case .productivity: return "Productive"
        case .social: return "Social"
        case .entertainment: return "Entertainment"
        case .games: return "Entertainment"
        case .education: return "Learning"
        case .health: return "Health"
        case .communication: return "Social"
        case .creativity: return "Productive"
        case .other: return "Other"
        default: return rawValue
        }
    }

    /// Color for this category
    var colorHex: String {
        switch self {
        case .productivity: return "#34C759"
        case .education: return "#5856D6"
        case .health: return "#30D158"
        case .creativity: return "#FF9500"
        case .social, .communication: return "#AF52DE"
        case .entertainment, .games: return "#FF2D55"
        case .news: return "#007AFF"
        default: return "#8E8E93"
        }
    }

    /// Icon for this category
    var icon: String {
        switch self {
        case .productivity: return "briefcase.fill"
        case .social: return "person.2.fill"
        case .entertainment: return "play.fill"
        case .games: return "gamecontroller.fill"
        case .education: return "book.fill"
        case .health: return "heart.fill"
        case .news: return "newspaper.fill"
        case .utilities: return "wrench.and.screwdriver.fill"
        case .communication: return "message.fill"
        case .creativity: return "paintbrush.fill"
        case .finance: return "dollarsign.circle.fill"
        case .travel: return "airplane"
        case .shopping: return "cart.fill"
        case .other: return "square.grid.2x2.fill"
        }
    }
}

// MARK: - Screen Time Summary Models

/// Summary of screen time for a specific day
struct ScreenTimeSummary {
    let date: Date
    let totalMinutes: Int
    let categoryUsages: [CategoryUsage]
    let pickupCount: Int
    let firstPickupTime: Date?

    struct CategoryUsage {
        let category: AppCategory
        let categoryName: String
        let durationMinutes: Int
        let topAppBundleId: String?
    }
}

// MARK: - Device Activity Extension

extension DeviceActivityName {
    static let daily = Self("daily")
}

// MARK: - Preview Helpers

extension ScreenTimeService {
    static func previewSummary() -> ScreenTimeSummary {
        ScreenTimeSummary(
            date: Date(),
            totalMinutes: 245,
            categoryUsages: [
                .init(category: .productivity, categoryName: "Productivity", durationMinutes: 120, topAppBundleId: "com.apple.Pages"),
                .init(category: .social, categoryName: "Social Networking", durationMinutes: 45, topAppBundleId: "com.twitter.twitter"),
                .init(category: .entertainment, categoryName: "Entertainment", durationMinutes: 60, topAppBundleId: "com.netflix.Netflix"),
                .init(category: .communication, categoryName: "Communication", durationMinutes: 20, topAppBundleId: "com.apple.MobileSMS")
            ],
            pickupCount: 42,
            firstPickupTime: Calendar.current.date(bySettingHour: 7, minute: 30, second: 0, of: Date())
        )
    }
}
