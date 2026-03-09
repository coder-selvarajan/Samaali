//
//  Theme.swift
//  DayArc
//
//  Created by Claude Code on 2/2/26.
//

import SwiftUI

/// App-wide theming and color definitions
enum Theme {
    // MARK: - Primary Colors (Indigo/Purple)
    static let primary = Color(hex: "#5856D6") ?? .indigo
    static let primaryLight = Color(hex: "#7B7AE0") ?? .indigo.opacity(0.7)
    static let primaryDark = Color(hex: "#4240B0") ?? .indigo

    // MARK: - Accent Colors
    static let accent = Color(hex: "#AF52DE") ?? .purple
    static let accentLight = Color(hex: "#C77DEB") ?? .purple.opacity(0.7)

    // MARK: - Semantic Colors
    static let success = Color.green
    static let warning = Color.orange
    static let error = Color.red
    static let info = Color.blue

    // MARK: - Activity Type Colors
    static let focus = Color(hex: "#5856D6") ?? .indigo
    static let productive = Color(hex: "#34C759") ?? .green
    static let leisure = Color(hex: "#FF9500") ?? .orange
    static let rest = Color(hex: "#5AC8FA") ?? .cyan

    // MARK: - Session Type Colors
    static func color(for sessionType: SessionType) -> Color {
        switch sessionType {
        case .focus: return primary
        case .shortBreak: return success
        case .longBreak: return warning
        }
    }

    // MARK: - Gradients
    static let primaryGradient = LinearGradient(
        colors: [primary, accent],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let cardGradient = LinearGradient(
        colors: [Color(.systemBackground), Color(.systemGray6)],
        startPoint: .top,
        endPoint: .bottom
    )

    // MARK: - Shadows
    static let cardShadow = Color.black.opacity(0.08)
    static let buttonShadow = primary.opacity(0.3)
}

// MARK: - View Modifiers

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Theme.primary)
            .clipShape(RoundedRectangle(cornerRadius: AppConstants.UI.cornerRadius))
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(Theme.primary)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Theme.primary.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: AppConstants.UI.cornerRadius))
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primary: PrimaryButtonStyle { PrimaryButtonStyle() }
}

extension ButtonStyle where Self == SecondaryButtonStyle {
    static var secondary: SecondaryButtonStyle { SecondaryButtonStyle() }
}
