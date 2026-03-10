# Samaali

`Samaali` is a personal iOS app designed to track, analyze, and improve how users spend their time throughout the day.

Unlike traditional productivity apps, Samaali focuses on awareness and reflection rather than pressure. The app combines manual activity logging, automation (screen time, timers), visual analytics, and on-device AI insights.

---

## Core Goals

- Help users understand where their time actually goes
- Reduce forgotten or untracked time gaps
- Classify activities meaningfully using tags
- Visualize daily and weekly activity patterns
- Provide intelligent, privacy-friendly insights
- Act as a lightweight task manager and reminder
- Encourage focused work using Pomodoro technique

---

## Key Features

### 1. Activity Logging Prompt
- On app launch or resume:
  - If the last recorded activity ended more than **X minutes ago** (default: 60),
    show a popup asking the user to log what they were doing.
- Popup options:
  - Log activity
  - Skip / Dismiss
- Threshold and behavior configurable via Settings.

---

### 2. Activity Classification
Activities can be tagged with one or more categories:

Examples:
- Productive
- Non-Productive
- Entertainment
- Learning
- Household Work
- Travel
- Family Time
- Social Service
- Custom user-defined tags

Each activity contains:
- Title / description
- Start time
- End time
- Duration
- Tags
- Source (Manual, Pomodoro, Screen Time, AI-suggested)

---

### 3. Home Dashboard & Charts
- Clean, visually pleasing charts showing:
  - Daily time distribution
  - Weekly trends
  - Tag-based breakdowns
- Chart types:
  - Donut / pie
  - Bar charts
  - Timeline view
- User can configure which charts appear.

---

### 4. Screen Time Integration
- Uses Apple Screen Time / Device Activity APIs (where permitted)
- Extracts app usage durations
- Converts them into activity entries
- Applies default or AI-suggested tags (e.g., Entertainment, Learning)
- Fully optional and configurable.

---

### 5. Pomodoro Timer
- Built-in Pomodoro timer
- Customizable durations (focus, break, long break)
- Automatically creates activity entries on completion
- Tags applied automatically (e.g., Productive, Learning)
- Works even without manual activity entry

---

### 6. Tasks & Todo
- Simple task management
- Tasks can be:
  - Scheduled
  - Linked to activities
  - Converted into Pomodoro sessions
- Reminder notifications supported.

---

### 7. Settings & Customization
Everything must be configurable:
- Activity prompt interval
- Default tags
- Chart visibility
- Screen time import
- Pomodoro durations
- AI suggestions on/off
- Notification preferences

---

### 8. On-Device AI Insights
- Uses Apple on-device AI (Core ML / Apple Intelligence APIs where available)
- Examples of insights:
  - “Most of your productive time happens between 9–11 AM”
  - “Entertainment time increases on weekends”
  - “Pomodoro sessions improve task completion”
- No cloud AI dependency by default.

---

## Architecture Notes

- SwiftUI
- MVVM
- Core Data or SwiftData for persistence
- Background tasks for passive tracking
- Privacy-first permissions handling

---

## Non-Goals (for now)

- Social features
- Gamification (streaks, leaderboards)
- Cloud sync (may be added later)
- Heavy automation without user consent

---

## Tone & UX Philosophy

- Calm
- Reflective
- Non-judgmental
- Insightful, not preachy

Samaali should feel like a quiet mirror for your day, not a boss.
