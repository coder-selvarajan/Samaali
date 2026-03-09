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
    @AppStorage(AppConstants.StorageKeys.appearanceMode) private var appearanceMode: Int = 0

    private var preferredColorScheme: ColorScheme? {
        switch appearanceMode {
        case 1: return .light
        case 2: return .dark
        default: return nil
        }
    }

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Activity.self,
            Tag.self,
            UserTask.self,
            PomodoroSession.self,
            Goal.self,
            GoalComment.self,
            Habit.self,
            HabitLog.self
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // During development, if schema changes cause issues, delete the old store
            print("ModelContainer creation failed: \(error)")
            print("Attempting to delete existing store and recreate...")

            // Get the default store URL
            let url = URL.applicationSupportDirectory.appending(path: "default.store")

            // Delete existing store files
            let fileManager = FileManager.default
            let storePaths = [
                url.path(),
                url.path() + "-shm",
                url.path() + "-wal"
            ]

            for path in storePaths {
                try? fileManager.removeItem(atPath: path)
            }

            // Try again
            do {
                return try ModelContainer(for: schema, configurations: [modelConfiguration])
            } catch {
                fatalError("Could not create ModelContainer after cleanup: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(appState)
                .preferredColorScheme(preferredColorScheme)
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
