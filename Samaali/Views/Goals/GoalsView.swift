//
//  GoalsView.swift
//  Samaali
//
//  Created by Claude Code on 2/6/26.
//

import SwiftUI
import SwiftData

struct GoalsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appState: AppState
    @Query(sort: \Goal.createdAt, order: .reverse) private var goals: [Goal]

    @State private var showingAddGoal = false
    @State private var selectedFilter: GoalFilter = .all

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var filteredGoals: [Goal] {
        switch selectedFilter {
        case .all:
            return goals
        case .active:
            return goals.filter { $0.status == .inProgress || $0.status == .notStarted }
        case .completed:
            return goals.filter { $0.status == .completed }
        case .onHold:
            return goals.filter { $0.status == .onHold }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Filter Pills
                    filterPills

                    // Goals Grid
                    if filteredGoals.isEmpty {
                        emptyState
                    } else {
                        goalsGrid
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Goals")
            .toolbarTitleDisplayMode(.inlineLarge)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddGoal = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(Theme.primary)
                    }
                }
            }
            .sheet(isPresented: $showingAddGoal) {
                AddGoalView()
            }
        }
    }

    // MARK: - Filter Pills
    private var filterPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(GoalFilter.allCases, id: \.self) { filter in
                    FilterPill(
                        title: filter.title,
                        count: countForFilter(filter),
                        isSelected: selectedFilter == filter
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedFilter = filter
                        }
                    }
                }
            }
        }
    }

    private func countForFilter(_ filter: GoalFilter) -> Int {
        switch filter {
        case .all:
            return goals.count
        case .active:
            return goals.filter { $0.status == .inProgress || $0.status == .notStarted }.count
        case .completed:
            return goals.filter { $0.status == .completed }.count
        case .onHold:
            return goals.filter { $0.status == .onHold }.count
        }
    }

    // MARK: - Goals Grid
    private var goalsGrid: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(filteredGoals) { goal in
                NavigationLink(destination: GoalDetailView(goal: goal)) {
                    GoalTileView(goal: goal)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
                .frame(height: 60)

            Image(systemName: "target")
                .font(.system(size: 60))
                .foregroundStyle(Theme.primary.opacity(0.5))

            Text(selectedFilter == .all ? "No Goals Yet" : "No \(selectedFilter.title) Goals")
                .font(.title2)
                .fontWeight(.semibold)

            Text(selectedFilter == .all
                 ? "Set your first goal and start tracking your progress!"
                 : "Try changing the filter or add a new goal.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            if selectedFilter == .all {
                Button {
                    showingAddGoal = true
                } label: {
                    Label("Add Goal", systemImage: "plus")
                }
                .buttonStyle(.primary)
                .padding(.top, 8)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Goal Filter
enum GoalFilter: CaseIterable {
    case all, active, completed, onHold

    var title: String {
        switch self {
        case .all: return "All"
        case .active: return "Active"
        case .completed: return "Completed"
        case .onHold: return "On Hold"
        }
    }
}

// MARK: - Filter Pill
struct FilterPill: View {
    let title: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)

                Text("\(count)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(isSelected ? .white.opacity(0.3) : Color(.systemGray5))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Theme.primary : Color(.systemBackground))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
        }
    }
}

// MARK: - Goal Tile View
struct GoalTileView: View {
    let goal: Goal

    private var tileColor: Color {
        Color(hex: goal.colorHex) ?? Theme.primary
    }

    private let textPrimary = Color(red: 0.2, green: 0.2, blue: 0.25)
    private let textSecondary = Color(red: 0.35, green: 0.35, blue: 0.4)

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with icon and status
            HStack {
                if let icon = goal.icon {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundStyle(textPrimary.opacity(0.8))
                } else {
                    Image(systemName: "target")
                        .font(.title2)
                        .foregroundStyle(textPrimary.opacity(0.8))
                }

                Spacer()

                Image(systemName: goal.status.icon)
                    .font(.caption)
                    .foregroundStyle(textSecondary)
            }

            Spacer()

            // Title
            Text(goal.title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(textPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            // Description
            if !goal.goalDescription.isEmpty {
                Text(goal.goalDescription)
                    .font(.caption)
                    .foregroundStyle(textSecondary)
                    .lineLimit(2)
            }

            // Timeline
            HStack(spacing: 4) {
                Image(systemName: "calendar")
                    .font(.caption2)
                Text(goal.timelineDescription)
                    .font(.caption2)
            }
            .foregroundStyle(textSecondary)

            // Progress bar
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Progress")
                        .font(.caption2)
                    Spacer()
                    Text("\(goal.progressPercentage)%")
                        .font(.caption2)
                        .fontWeight(.medium)
                }
                .foregroundStyle(textSecondary)

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(textPrimary.opacity(0.15))
                            .frame(height: 6)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(textPrimary.opacity(0.5))
                            .frame(width: geometry.size.width * goal.progress, height: 6)
                    }
                }
                .frame(height: 6)
            }
        }
        .padding(16)
        .frame(minHeight: 180)
        .background(
            LinearGradient(
                colors: [tileColor, tileColor.opacity(0.85)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: AppConstants.UI.cornerRadius))
        .shadow(color: tileColor.opacity(0.25), radius: 6, y: 3)
    }
}

#Preview {
    GoalsView()
        .modelContainer(for: [Goal.self, GoalComment.self])
}
