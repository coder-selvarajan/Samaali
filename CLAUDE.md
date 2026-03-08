# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run

This is a native iOS app (Xcode project, no SPM/CocoaPods dependencies). Build and run with:

```bash
xcodebuild -project TimeTrace.xcodeproj -scheme TimeTrace -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16' build
```

There are no test targets configured. No linter is set up.

## Architecture

**Pattern:** MVVM + Service-Oriented Architecture
**UI:** SwiftUI
**Data:** SwiftData (6 model types)
**Deployment:** iOS 26.1, Swift 5.0
**Dependencies:** None — uses only Apple-native frameworks (NaturalLanguage, FamilyControls, DeviceActivity, ManagedSettings)

### Data Flow

Views → ViewModels (`@Observable`, `@MainActor`) → Services (`@MainActor`) → SwiftData `ModelContext`

Global navigation state is managed by `AppState` (`@MainActor ObservableObject`) with 5 tabs: home, activities, timer, tasks, goals.

### Key Directories

- `TimeTrace/Models/` — SwiftData `@Model` classes: Activity, Tag, UserTask, PomodoroSession, Goal, GoalComment. Also Insight (value type, not persisted).
- `TimeTrace/Services/` — Business logic: ActivityService, TagService, SettingsService, ScreenTimeService, AIInsightsService, NotificationService.
- `TimeTrace/ViewModels/` — HomeViewModel, PomodoroViewModel, ScreenTimeViewModel, AIInsightsViewModel.
- `TimeTrace/Views/` — Organized by feature: Home, Activities, Timer, Tasks, Goals, Insights, ScreenTime, Settings, plus Main (tab view) and Components.
- `TimeTrace/Utilities/` — Constants.swift (config values, UserDefaults keys), Theme.swift (colors, gradients, button styles).
- `TimeTrace/Extensions/` — Date+Extensions.swift, Color+Hex.swift.
- `TimeTrace/App/` — AppState.swift (global navigation state).

### Model Container Setup

`TimeTraceApp.swift` creates the SwiftData container with all 6 model types. On schema mismatch, it deletes and recreates the store (development convenience — change before shipping). System tags are initialized on first launch via `TagService.initializeSystemTagsIfNeeded()`.

### Activity Gap Detection

When the app becomes active, it checks time elapsed since the last activity. If it exceeds the configurable threshold (default 60 min), an `ActivityPromptView` modal is shown. This logic lives in `TimeTraceApp.swift` using scene phase observation.

## Design Principles

- **Privacy-first:** All AI/insights run on-device via NaturalLanguage framework. No cloud dependency.
- **Apple-native only:** No third-party dependencies. Prefer Apple frameworks.
- **Calm UX:** Non-judgmental, reflective tone. The app is "a quiet mirror for your day, not a boss."
- **Configurable:** All thresholds, durations, and feature toggles are managed through `SettingsService` backed by UserDefaults.
