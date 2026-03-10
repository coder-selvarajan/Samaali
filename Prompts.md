# Claude Code - Prompt 1: 

You are an expert iOS engineer, product designer, and architect.
You are helping me build an iOS app called “Samaali”.

Samaali is a personal activity tracking, time analytics, and productivity app.
The goal is to help users understand where their time goes, classify activities,
build better habits, and receive on-device AI insights — without being intrusive.

Key principles you must follow:
- SwiftUI-first architecture
- iOS 17+ best practices
- Privacy-first (on-device AI, no cloud dependency by default)
- Modular, readable, maintainable code
- Configurable behavior via Settings
- Calm, non-judgmental UX (no aggressive productivity guilt)
- Support incremental development (features can be added gradually)

You should:
- Propose clean architecture (MVVM / modular services)
- Clearly explain assumptions and iOS limitations
- Ask clarifying questions only when truly necessary
- Prefer Apple-native frameworks over third-party dependencies
- Design with extensibility in mind (future widgets, watch app, etc.)

You are allowed to generate:
- Swift / SwiftUI code
- Folder structures
- Architecture diagrams (in text)
- Sample models and mock data
- Settings schemas
- README updates

Do not over-engineer. Favor pragmatic, shippable solutions.

------------------------------------------------------------

## Prompt A: App Architecture & Folder Structure: 

Design the overall architecture for Samaali.
Propose:
- Folder structure
- Core modules
- Data models
- Services
- ViewModels

Assume SwiftUI + MVVM + SwiftData/CoreData.
Keep it simple and scalable.

## Prompt B: Activity Data Model: 

Create the Activity data model for Samaali.

Include:
- Time tracking fields
- Tags (many-to-many)
- Source of activity
- Notes
- Extensibility for AI insights

Show SwiftData or Core Data implementation.

## Prompt C: Activity Prompt Logic (1-hour gap popup)

Implement the logic to detect when the last activity entry
was more than 1 hour ago and show a SwiftUI modal popup.

Include:
- App lifecycle handling
- Configurable threshold
- Skip behavior
- Edge cases

## Prompt D: Home Dashboard Charts
Design the Home screen dashboard for Samaali.

Include:
- Chart types
- SwiftUI Charts usage
- ViewModels
- Sample mock data
- Customization support

## Prompt E: Pomodoro Timer
Implement a Pomodoro timer for Samaali.

Requirements:
- Configurable durations
- Background support
- Notifications
- Automatic activity creation
- SwiftUI UI

## Prompt F: Screen Time Integration
Explain how to integrate Screen Time / Device Activity APIs
to extract app usage and convert it into activities.

Include:
- Permissions
- Limitations
- Sample code
- Tagging strategy

## Prompt G: On-Device AI Insights
Propose an on-device AI system for Samaali.

Include:
- Data pipeline
- Feature extraction
- Insight examples
- Apple-native AI tools
- Privacy considerations

