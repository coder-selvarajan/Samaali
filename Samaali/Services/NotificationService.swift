//
//  NotificationService.swift
//  Samaali
//
//  Created by Claude Code on 2/2/26.
//

import Foundation
import UserNotifications

/// Service for managing local notifications
final class NotificationService {
    static let shared = NotificationService()

    private init() {}

    // MARK: - Authorization

    func requestAuthorization() async throws -> Bool {
        let center = UNUserNotificationCenter.current()
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]

        return try await center.requestAuthorization(options: options)
    }

    func checkAuthorizationStatus() async -> UNAuthorizationStatus {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        return settings.authorizationStatus
    }

    // MARK: - Pomodoro Notifications

    func schedulePomodoroComplete(duration: TimeInterval, sessionType: SessionType) {
        let content = UNMutableNotificationContent()

        switch sessionType {
        case .focus:
            content.title = "Focus Session Complete"
            content.body = "Great work! Time for a break."
        case .shortBreak:
            content.title = "Break Over"
            content.body = "Ready to focus again?"
        case .longBreak:
            content.title = "Long Break Over"
            content.body = "Feeling refreshed? Let's continue!"
        }

        content.sound = .default
        content.categoryIdentifier = "POMODORO"

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: duration,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: "pomodoro-\(sessionType.rawValue)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    func cancelPomodoroNotifications() {
        let identifiers = SessionType.allCases.map { "pomodoro-\($0.rawValue)" }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    // MARK: - Task Reminders

    func scheduleTaskReminder(task: UserTask) {
        guard let reminderDate = task.reminderDate else { return }

        let content = UNMutableNotificationContent()
        content.title = "Task Reminder"
        content.body = task.title
        content.sound = .default
        content.categoryIdentifier = "TASK"

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: reminderDate
        )
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: components,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: "task-\(task.id.uuidString)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    func cancelTaskReminder(taskId: UUID) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["task-\(taskId.uuidString)"]
        )
    }

    // MARK: - Activity Prompt Notification

    func scheduleActivityPrompt(afterMinutes: Int) {
        let content = UNMutableNotificationContent()
        content.title = "What have you been up to?"
        content.body = "Log your recent activities to keep track of your time."
        content.sound = .default
        content.categoryIdentifier = "ACTIVITY_PROMPT"

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(afterMinutes * 60),
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: "activity-prompt",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Clear All

    func clearAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
}
