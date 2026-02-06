//
//  AppState.swift
//  TimeTrace
//
//  Created by Claude Code on 2/2/26.
//

import SwiftUI
import Combine

/// Global app state observable across all views
@MainActor
final class AppState: ObservableObject {

    // MARK: - Navigation State
    @Published var selectedTab: Tab = .home
    @Published var showActivityPrompt: Bool = false
    @Published var showSettings: Bool = false

    // MARK: - App Lifecycle
    @Published var isActive: Bool = true
    @Published var lastActiveDate: Date?

    // MARK: - Tab Definition
    enum Tab: Int, CaseIterable, Identifiable {
        case home = 0
        case activities = 1
        case timer = 2
        case tasks = 3
        case goals = 4

        var id: Int { rawValue }

        var title: String {
            switch self {
            case .home: return "Home"
            case .activities: return "Activities"
            case .timer: return "Timer"
            case .tasks: return "Tasks"
            case .goals: return "Goals"
            }
        }

        var icon: String {
            switch self {
            case .home: return "house.fill"
            case .activities: return "list.bullet.clipboard"
            case .timer: return "timer"
            case .tasks: return "checklist"
            case .goals: return "target"
            }
        }
    }
}
