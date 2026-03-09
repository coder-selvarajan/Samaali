//
//  Constants.swift
//  DayArc
//
//  Created by Claude Code on 2/2/26.
//

import Foundation

enum AppConstants {

    // MARK: - Activity Tracking
    enum ActivityTracking {
        static let defaultGapThresholdMinutes: Int = 60
        static let minimumActivityDurationSeconds: Int = 60
    }

    // MARK: - Pomodoro Defaults
    enum Pomodoro {
        static let defaultFocusDurationMinutes: Int = 25
        static let defaultShortBreakMinutes: Int = 5
        static let defaultLongBreakMinutes: Int = 15
        static let sessionsBeforeLongBreak: Int = 4
    }

    // MARK: - UI
    enum UI {
        static let animationDuration: Double = 0.3
        static let cornerRadius: CGFloat = 12
        static let shadowRadius: CGFloat = 4
    }

    // MARK: - Storage Keys
    enum StorageKeys {
        static let lastActivityEndTime = "lastActivityEndTime"
        static let activityGapThreshold = "activityGapThreshold"
        static let pomodoroFocusDuration = "pomodoroFocusDuration"
        static let pomodoroShortBreak = "pomodoroShortBreak"
        static let pomodoroLongBreak = "pomodoroLongBreak"
        static let enableScreenTimeImport = "enableScreenTimeImport"
        static let enableAIInsights = "enableAIInsights"
        static let enableNotifications = "enableNotifications"

        // Screen Time
        static let screenTimeAuthorized = "screenTimeAuthorized"
        static let lastScreenTimeImport = "lastScreenTimeImport"
        static let screenTimeAutoImport = "screenTimeAutoImport"

        // Appearance
        static let appearanceMode = "appearanceMode"

        // AI Insights
        static let lastInsightGenerationDate = "lastInsightGenerationDate"
        static let insightRefreshInterval = "insightRefreshInterval"
        static let enableProductivityScoring = "enableProductivityScoring"
        static let enableSentimentAnalysis = "enableSentimentAnalysis"
        static let enablePatternDetection = "enablePatternDetection"
    }

    // MARK: - AI Insights
    enum AIInsights {
        static let defaultRefreshIntervalHours: Int = 24
        static let minimumActivitiesForInsights: Int = 5
        static let minimumDaysForPatterns: Int = 7
        static let maxInsightsToShow: Int = 5
    }

    // MARK: - Screen Time
    enum ScreenTime {
        static let minimumUsageMinutesToImport: Int = 5
        static let defaultAutoImportEnabled: Bool = false
    }
}
