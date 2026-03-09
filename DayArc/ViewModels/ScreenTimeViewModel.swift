//
//  ScreenTimeViewModel.swift
//  DayArc
//
//  Created by Claude Code on 2/6/26.
//

import Foundation
import SwiftData
import SwiftUI

/// ViewModel for Screen Time integration features
@MainActor
@Observable
final class ScreenTimeViewModel {
    // MARK: - Published State

    var isAuthorized = false
    var authorizationStatus: ScreenTimeService.AuthorizationStatus = .notDetermined
    var isLoading = false
    var error: ScreenTimeError?
    var showError = false

    // Screen Time Data
    var todaySummary: ScreenTimeSummary?
    var weekSummaries: [ScreenTimeSummary] = []
    var importedActivities: [Activity] = []

    // Import State
    var isImporting = false
    var lastImportDate: Date?
    var importCount = 0

    // MARK: - Dependencies

    private let screenTimeService: ScreenTimeService
    private let modelContext: ModelContext

    // MARK: - Initialization

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.screenTimeService = ScreenTimeService(modelContext: modelContext)
        refreshAuthorizationStatus()
    }

    // MARK: - Authorization

    func refreshAuthorizationStatus() {
        screenTimeService.checkAuthorizationStatus()
        authorizationStatus = screenTimeService.authorizationStatus
        isAuthorized = authorizationStatus == .authorized
    }

    func requestAuthorization() async {
        isLoading = true
        error = nil

        do {
            let granted = try await screenTimeService.requestAuthorization()
            isAuthorized = granted
            refreshAuthorizationStatus()

            if granted {
                await loadTodaySummary()
            }
        } catch let screenTimeError as ScreenTimeError {
            error = screenTimeError
            showError = true
        } catch {
            self.error = .authorizationFailed(error)
            showError = true
        }

        isLoading = false
    }

    // MARK: - Data Loading

    func loadTodaySummary() async {
        guard isAuthorized else { return }
        isLoading = true

        // In a real implementation, this would fetch from DeviceActivityReport
        // Due to API limitations, we use mock data for demonstration
        todaySummary = ScreenTimeService.previewSummary()

        isLoading = false
    }

    func loadWeekSummaries() async {
        guard isAuthorized else { return }
        isLoading = true

        // Generate mock summaries for the week
        let calendar = Calendar.current
        weekSummaries = (0..<7).compactMap { daysAgo in
            guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: Date()) else { return nil }

            // Create varied mock data
            let baseMinutes = 200 + Int.random(in: -50...100)
            return ScreenTimeSummary(
                date: date,
                totalMinutes: baseMinutes,
                categoryUsages: [
                    .init(category: .productivity, categoryName: "Productivity", durationMinutes: Int(Double(baseMinutes) * 0.4), topAppBundleId: nil),
                    .init(category: .social, categoryName: "Social", durationMinutes: Int(Double(baseMinutes) * 0.25), topAppBundleId: nil),
                    .init(category: .entertainment, categoryName: "Entertainment", durationMinutes: Int(Double(baseMinutes) * 0.2), topAppBundleId: nil),
                    .init(category: .other, categoryName: "Other", durationMinutes: Int(Double(baseMinutes) * 0.15), topAppBundleId: nil)
                ],
                pickupCount: 30 + Int.random(in: -10...20),
                firstPickupTime: calendar.date(bySettingHour: 7 + Int.random(in: 0...2), minute: Int.random(in: 0...59), second: 0, of: date)
            )
        }

        isLoading = false
    }

    // MARK: - Import Functions

    func importTodayAsActivities() async {
        guard let summary = todaySummary else { return }
        isImporting = true
        error = nil

        do {
            let activities = try screenTimeService.importScreenTimeSummary(summary)
            importedActivities = activities
            importCount = activities.count
            lastImportDate = Date()
        } catch let screenTimeError as ScreenTimeError {
            error = screenTimeError
            showError = true
        } catch {
            self.error = .importFailed(error)
            showError = true
        }

        isImporting = false
    }

    func importSelectedCategories(_ categories: Set<AppCategory>) async {
        guard let summary = todaySummary else { return }
        isImporting = true

        let filteredUsages = summary.categoryUsages.filter { categories.contains($0.category) }
        let filteredSummary = ScreenTimeSummary(
            date: summary.date,
            totalMinutes: filteredUsages.reduce(0) { $0 + $1.durationMinutes },
            categoryUsages: filteredUsages,
            pickupCount: summary.pickupCount,
            firstPickupTime: summary.firstPickupTime
        )

        do {
            let activities = try screenTimeService.importScreenTimeSummary(filteredSummary)
            importedActivities.append(contentsOf: activities)
            importCount += activities.count
        } catch {
            self.error = .importFailed(error)
            showError = true
        }

        isImporting = false
    }

    // MARK: - Computed Properties

    var formattedTotalTime: String {
        guard let summary = todaySummary else { return "No data" }
        let hours = summary.totalMinutes / 60
        let minutes = summary.totalMinutes % 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    var productiveTimePercentage: Double {
        guard let summary = todaySummary, summary.totalMinutes > 0 else { return 0 }
        let productiveMinutes = summary.categoryUsages
            .filter { $0.category.defaultProductivityScore >= 0.6 }
            .reduce(0) { $0 + $1.durationMinutes }
        return Double(productiveMinutes) / Double(summary.totalMinutes)
    }

    var topCategory: AppCategory? {
        todaySummary?.categoryUsages.max(by: { $0.durationMinutes < $1.durationMinutes })?.category
    }

    var canImport: Bool {
        isAuthorized && todaySummary != nil && !isImporting
    }
}

// MARK: - Preview Helper

extension ScreenTimeViewModel {
    static func preview(modelContext: ModelContext) -> ScreenTimeViewModel {
        let vm = ScreenTimeViewModel(modelContext: modelContext)
        vm.isAuthorized = true
        vm.authorizationStatus = .authorized
        vm.todaySummary = ScreenTimeService.previewSummary()
        return vm
    }
}
