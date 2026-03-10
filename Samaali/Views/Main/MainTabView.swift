//
//  MainTabView.swift
//  Samaali
//
//  Created by Claude Code on 2/2/26.
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        TabView(selection: $appState.selectedTab) {
            HomeView()
                .tabItem {
                    Label(AppState.Tab.home.title, systemImage: AppState.Tab.home.icon)
                }
                .tag(AppState.Tab.home)

            PomodoroView()
                .tabItem {
                    Label(AppState.Tab.timer.title, systemImage: AppState.Tab.timer.icon)
                }
                .tag(AppState.Tab.timer)

            TasksView()
                .tabItem {
                    Label(AppState.Tab.tasks.title, systemImage: AppState.Tab.tasks.icon)
                }
                .tag(AppState.Tab.tasks)

            HabitsView()
                .tabItem {
                    Label(AppState.Tab.habits.title, systemImage: AppState.Tab.habits.icon)
                }
                .tag(AppState.Tab.habits)

            GoalsView()
                .tabItem {
                    Label(AppState.Tab.goals.title, systemImage: AppState.Tab.goals.icon)
                }
                .tag(AppState.Tab.goals)
        }
        .tint(Theme.primary)
        .sheet(isPresented: $appState.showActivityPrompt) {
            ActivityPromptView()
                .interactiveDismissDisabled()
        }
        .sheet(isPresented: $appState.showSettings) {
            SettingsView()
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AppState())
}
