//
//  TimeTraceApp.swift
//  TimeTrace
//
//  Created by Selvarajan on 2/2/26.
//

import SwiftUI
import SwiftData

@main
struct TimeTraceApp: App {
    @StateObject private var appState = AppState()
    @Environment(\.scenePhase) private var scenePhase

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Activity.self,
            Tag.self,
            UserTask.self,
            PomodoroSession.self
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(appState)
                .onAppear {
                    initializeAppData()
                }
                .onChange(of: scenePhase) { oldPhase, newPhase in
                    handleScenePhaseChange(from: oldPhase, to: newPhase)
                }
        }
        .modelContainer(sharedModelContainer)
    }

    // MARK: - Initialization

    @MainActor
    private func initializeAppData() {
        let context = sharedModelContainer.mainContext
        let tagService = TagService(modelContext: context)

        do {
            try tagService.initializeSystemTagsIfNeeded()
        } catch {
            print("Failed to initialize system tags: \(error)")
        }
    }

    // MARK: - Lifecycle

    private func handleScenePhaseChange(from oldPhase: ScenePhase, to newPhase: ScenePhase) {
        switch newPhase {
        case .active:
            appState.isActive = true
            Task { @MainActor in
                checkActivityGap()
            }
        case .inactive:
            appState.isActive = false
        case .background:
            appState.lastActiveDate = Date()
        @unknown default:
            break
        }
    }

    @MainActor
    private func checkActivityGap() {
        let context = sharedModelContainer.mainContext
        let activityService = ActivityService(modelContext: context)
        let settingsService = SettingsService()

        do {
            if try activityService.shouldPromptForActivity(threshold: settingsService.activityGapThreshold) {
                appState.showActivityPrompt = true
            }
        } catch {
            print("Failed to check activity gap: \(error)")
        }
    }
}
