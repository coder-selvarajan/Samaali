# Samaali

**Samaali** is a privacy-first iOS app for tracking, reflecting on, and improving how you spend your time. It combines manual activity logging, Pomodoro technique, habit tracking, goal setting, screen time integration, and on-device AI insights — all without any cloud dependency.

> *A quiet mirror for your day, not a boss.*

---

## Tech Stack

- **UI:** SwiftUI
- **Architecture:** MVVM + Service-Oriented
- **Data:** SwiftData (8 model types)
- **AI:** Apple NaturalLanguage framework (on-device)
- **Screen Time:** FamilyControls, DeviceActivity, ManagedSettings
- **Target:** iOS 16.1+, Swift 5.0
- **Dependencies:** None — Apple-native frameworks only

---

## Features

### Activity Tracking
- Log activities manually with title, notes, start/end times, and tags
- Activities can also be created from Pomodoro sessions, screen time imports, or AI suggestions
- Track productivity score (0–1), energy level (1–5), mood level (1–5), and sentiment
- Chronological timeline grouped by date with search by title, notes, or tags
- Source tracking: Manual, Pomodoro, Screen Time, AI-Suggested

### Activity Gap Detection
- Detects idle periods when the app is reopened after a configurable threshold (default: 60 min, range: 15–180 min)
- Prompts with quick-log suggestions (Meeting, Deep Work, Break, etc.) or detailed entry
- 30-minute snooze option to defer logging

### Pomodoro Timer
- Focus (default 25 min), Short Break (5 min), Long Break (15 min) — all configurable
- Long break triggers after 4 focus sessions
- Circular progress ring with gradient backgrounds matching session type
- Background timer support — continues when the app is minimized
- Automatically creates activity records on session completion
- Local notifications on timer completion

### Tasks
- Task management with priority levels (Low, Medium, High) and color coding
- Grouped views: Overdue, Today, Later, No Date, Completed
- Due dates, optional reminders via local notifications
- Tag assignment and optional link to activities
- Toggle completion with tap

### Goals
- Long-term goal tracking with status lifecycle: Not Started → In Progress → On Hold → Completed / Cancelled
- Progress tracking with milestone counters and progress bars
- Start date and optional target date with days remaining/overdue display
- Custom colors and icons per goal
- Reflective comments/notes on each goal with relative timestamps
- Grid layout with filter pills (All, Active, Completed, On Hold)

### Habits
- Daily habit tracking with toggle-based completion
- Date navigation with week overview grid
- Current streak calculation and 30-day completion rate
- Archive/unarchive for inactive habits
- Custom icons and colors per habit

### AI Insights (On-Device)
- **Sentiment Analysis** — NaturalLanguage framework analyzes activity notes
- **Productivity Scoring** — 7-factor algorithm: time of day, duration, tags, sentiment, Pomodoro usage, screen time, and source
- **Pattern Detection** — Peak productivity hours, peak days, activity streaks (current, longest, total)
- **Category Suggestions** — Keyword-based NLP categorization across 10 categories
- **Insight Types:** Achievement, Pattern, Trend, Recommendation, Tip, Warning
- **Dashboards:** Streak indicator, weekly summary (total time, productive time, active days), daily insights, productivity trend chart
- Minimum 5 activities required; 7+ days recommended for pattern detection
- Can be fully disabled in settings

### Screen Time Integration
- Uses Apple's DeviceActivity and FamilyControls APIs
- Imports app usage by category as activities (minimum 5 min threshold)
- Auto-assigns productivity scores by category (e.g., Productivity: 0.9, Entertainment: 0.2)
- Auto-tags imported activities (Productive, Social, Entertainment, Learning, Health)
- Fully optional — requires explicit user authorization

### Home Dashboard
- Today's activities summary with total tracked time
- Weekly activity overview
- Pomodoro session count
- Daily chart data and category breakdown
- Quick access to all features via 5-tab navigation: Home, Timer, Tasks, Habits, Goals

### Tags & Categorization
- 10 system tags initialized on first launch: Productive, Non-Productive, Entertainment, Learning, Household, Travel, Family, Social, Health, Work
- Custom user-defined tags with colors and icons
- Tags are shared across activities, tasks, and goals

### Settings
- **Appearance:** System, Light, or Dark mode
- **Activity Tracking:** Gap detection threshold (15–180 min)
- **Pomodoro:** Focus duration (5–60 min), short break (1–15 min), long break (10–30 min)
- **Feature Toggles:** Screen Time import, AI Insights, Notifications
- **AI Components:** Individual toggles for productivity scoring, sentiment analysis, pattern detection
- All settings persisted via UserDefaults with reset-to-defaults option

### Notifications
- Pomodoro timer completion (focus/break/long break variants)
- Task reminders at scheduled dates
- Activity prompt notifications
- Centrally managed via NotificationService

---

## Architecture

```
Views → ViewModels (@Observable, @MainActor) → Services (@MainActor) → SwiftData ModelContext
```

### Key Directories

| Directory | Contents |
|-----------|----------|
| `Samaali/Models/` | SwiftData `@Model` classes: Activity, Tag, UserTask, PomodoroSession, Goal, GoalComment, Habit, HabitLog. Plus Insight (value type). |
| `Samaali/Services/` | ActivityService, TagService, HabitService, SettingsService, ScreenTimeService, AIInsightsService, NotificationService |
| `Samaali/ViewModels/` | HomeViewModel, PomodoroViewModel, ScreenTimeViewModel, AIInsightsViewModel |
| `Samaali/Views/` | Organized by feature: Home, Activities, Timer, Tasks, Goals, Habits, Insights, ScreenTime, Settings, Components |
| `Samaali/Utilities/` | Constants.swift, Theme.swift |
| `Samaali/Extensions/` | Date+Extensions.swift, Color+Hex.swift |
| `Samaali/App/` | SamaaliApp.swift (entry point), AppState.swift (global navigation) |

### Design System
- **Primary:** Indigo (#5856D6) with purple accent (#AF52DE)
- **Gradients:** Indigo → Purple (primary), Background → Gray (cards)
- **Semantic colors:** Success (green), Warning (orange), Error (red), Info (blue)
- Custom button styles (PrimaryButtonStyle, SecondaryButtonStyle)

---

## Design Principles

- **Privacy-first** — All AI and insights run on-device. No cloud dependency.
- **Apple-native only** — Zero third-party dependencies.
- **Calm UX** — Non-judgmental, reflective tone throughout.
- **Configurable** — All thresholds, durations, and features are user-adjustable.

---

## Build & Run

```bash
xcodebuild -project Samaali.xcodeproj -scheme Samaali -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 16' build
```

No external dependencies to install. Open `Samaali.xcodeproj` in Xcode and run.

> **Note:** On schema mismatch, the app deletes and recreates the SwiftData store automatically (development convenience — should be changed before shipping).
