//
//  SettingsService.swift
//  TimeTrace
//
//  Created by Claude Code on 2/2/26.
//

import Foundation

/// Service for managing app settings using UserDefaults
final class SettingsService {
    private let defaults = UserDefaults.standard

    // MARK: - Activity Settings

    var activityGapThreshold: Int {
        get {
            let value = defaults.integer(forKey: AppConstants.StorageKeys.activityGapThreshold)
            return value > 0 ? value : AppConstants.ActivityTracking.defaultGapThresholdMinutes
        }
        set {
            defaults.set(newValue, forKey: AppConstants.StorageKeys.activityGapThreshold)
        }
    }

    var lastActivityEndTime: Date? {
        get {
            let interval = defaults.double(forKey: AppConstants.StorageKeys.lastActivityEndTime)
            return interval > 0 ? Date(timeIntervalSince1970: interval) : nil
        }
        set {
            defaults.set(newValue?.timeIntervalSince1970 ?? 0, forKey: AppConstants.StorageKeys.lastActivityEndTime)
        }
    }

    // MARK: - Pomodoro Settings

    var pomodoroFocusDuration: Int {
        get {
            let value = defaults.integer(forKey: AppConstants.StorageKeys.pomodoroFocusDuration)
            return value > 0 ? value : AppConstants.Pomodoro.defaultFocusDurationMinutes
        }
        set {
            defaults.set(newValue, forKey: AppConstants.StorageKeys.pomodoroFocusDuration)
        }
    }

    var pomodoroShortBreak: Int {
        get {
            let value = defaults.integer(forKey: AppConstants.StorageKeys.pomodoroShortBreak)
            return value > 0 ? value : AppConstants.Pomodoro.defaultShortBreakMinutes
        }
        set {
            defaults.set(newValue, forKey: AppConstants.StorageKeys.pomodoroShortBreak)
        }
    }

    var pomodoroLongBreak: Int {
        get {
            let value = defaults.integer(forKey: AppConstants.StorageKeys.pomodoroLongBreak)
            return value > 0 ? value : AppConstants.Pomodoro.defaultLongBreakMinutes
        }
        set {
            defaults.set(newValue, forKey: AppConstants.StorageKeys.pomodoroLongBreak)
        }
    }

    // MARK: - Feature Toggles

    var enableScreenTimeImport: Bool {
        get { defaults.bool(forKey: AppConstants.StorageKeys.enableScreenTimeImport) }
        set { defaults.set(newValue, forKey: AppConstants.StorageKeys.enableScreenTimeImport) }
    }

    var enableAIInsights: Bool {
        get {
            if defaults.object(forKey: AppConstants.StorageKeys.enableAIInsights) == nil {
                return true // Default to true
            }
            return defaults.bool(forKey: AppConstants.StorageKeys.enableAIInsights)
        }
        set { defaults.set(newValue, forKey: AppConstants.StorageKeys.enableAIInsights) }
    }

    var enableNotifications: Bool {
        get {
            if defaults.object(forKey: AppConstants.StorageKeys.enableNotifications) == nil {
                return true // Default to true
            }
            return defaults.bool(forKey: AppConstants.StorageKeys.enableNotifications)
        }
        set { defaults.set(newValue, forKey: AppConstants.StorageKeys.enableNotifications) }
    }

    // MARK: - Computed Properties

    var shouldShowActivityPrompt: Bool {
        guard let lastEnd = lastActivityEndTime else {
            return true // No recorded activity, show prompt
        }
        let minutesSince = Date().minutesSince(lastEnd)
        return minutesSince >= activityGapThreshold
    }

    // MARK: - Methods

    func updateLastActivityEndTime(_ date: Date) {
        lastActivityEndTime = date
    }

    func resetToDefaults() {
        activityGapThreshold = AppConstants.ActivityTracking.defaultGapThresholdMinutes
        pomodoroFocusDuration = AppConstants.Pomodoro.defaultFocusDurationMinutes
        pomodoroShortBreak = AppConstants.Pomodoro.defaultShortBreakMinutes
        pomodoroLongBreak = AppConstants.Pomodoro.defaultLongBreakMinutes
        enableScreenTimeImport = false
        enableAIInsights = true
        enableNotifications = true
    }
}
