//
//  HomeView.swift
//  TimeTrace
//
//  Created by Claude Code on 2/2/26.
//

import SwiftUI
import SwiftData
import Charts

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appState: AppState
    @Query(sort: \Activity.startTime, order: .reverse)
    private var recentActivities: [Activity]

    @State private var viewModel: HomeViewModel?
    @State private var insightsViewModel: AIInsightsViewModel?
    @State private var showingAddActivity = false

    @AppStorage(AppConstants.StorageKeys.enableAIInsights)
    private var enableAIInsights = true

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    welcomeSection
                    quickStatsSection
                    if enableAIInsights {
                        aiInsightsSummarySection
                    }
                    weeklyChartSection
                    categoryBreakdownSection
                    recentActivitiesSection
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("TimeTrace")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        appState.showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundStyle(Theme.primary)
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddActivity = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(Theme.primary)
                    }
                }
            }
            .sheet(isPresented: $showingAddActivity) {
                AddActivityView()
            }
            .onAppear {
                initializeViewModel()
            }
            .refreshable {
                viewModel?.loadDashboardData()
            }
        }
    }

    private func initializeViewModel() {
        if viewModel == nil {
            viewModel = HomeViewModel(modelContext: modelContext)
            viewModel?.loadDashboardData()
        }
        if insightsViewModel == nil && enableAIInsights {
            insightsViewModel = AIInsightsViewModel(modelContext: modelContext)
            Task {
                await insightsViewModel?.loadInsights()
                await insightsViewModel?.loadStreakInfo()
            }
        }
    }

    // MARK: - Welcome Section

    private var welcomeSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(greeting)
                .font(.title2)
                .fontWeight(.semibold)
            Text(Date(), style: .date)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }

    // MARK: - AI Insights Summary Section

    private var aiInsightsSummarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Insights")
                    .font(.headline)
                Spacer()
                NavigationLink {
                    AIInsightsView()
                } label: {
                    Text("See All")
                        .font(.subheadline)
                        .foregroundStyle(Theme.primary)
                }
            }

            if let vm = insightsViewModel {
                // Streak indicator
                if let streak = vm.streakInfo, streak.currentStreak > 0 {
                    HStack(spacing: 12) {
                        Image(systemName: "flame.fill")
                            .font(.title2)
                            .foregroundStyle(.orange)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(streak.currentStreak)-day streak")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text("Keep tracking to maintain your streak!")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()
                    }
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [.orange.opacity(0.15), .red.opacity(0.1)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: AppConstants.UI.cornerRadius))
                }

                // Top insight
                if let topInsight = vm.topInsight {
                    CompactInsightCard(insight: topInsight)
                }
            } else {
                insightsLoadingPlaceholder
            }
        }
    }

    private var insightsLoadingPlaceholder: some View {
        HStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.title2)
                .foregroundStyle(Theme.primary)
            VStack(alignment: .leading, spacing: 4) {
                Text("Loading insights...")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text("Analyzing your activity patterns")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            ProgressView()
        }
        .padding()
        .background(Theme.primary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: AppConstants.UI.cornerRadius))
    }

    // MARK: - Quick Stats Section

    private var quickStatsSection: some View {
        HStack(spacing: 12) {
            StatCard(
                title: "Today",
                value: viewModel?.formattedTodayTotal ?? "0m",
                subtitle: "tracked",
                icon: "clock.fill",
                color: Theme.primary
            )
            StatCard(
                title: "Productive",
                value: viewModel?.formattedProductiveTime ?? "0m",
                subtitle: "focus time",
                icon: "bolt.fill",
                color: Theme.success
            )
            StatCard(
                title: "Sessions",
                value: "\(viewModel?.pomodoroSessionsToday ?? 0)",
                subtitle: "pomodoros",
                icon: "timer",
                color: Theme.accent
            )
        }
    }

    // MARK: - Weekly Chart Section

    private var weeklyChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This Week")
                .font(.headline)

            if let chartData = viewModel?.dailyChartData, !chartData.isEmpty {
                Chart(chartData) { point in
                    BarMark(
                        x: .value("Day", point.dayLabel),
                        y: .value("Hours", point.totalHours)
                    )
                    .foregroundStyle(Theme.primary.gradient)
                    .cornerRadius(4)
                }
                .frame(height: 160)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(Color(.systemGray4))
                        AxisValueLabel {
                            if let hours = value.as(Double.self) {
                                Text("\(Int(hours))h")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let label = value.as(String.self) {
                                Text(label)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: AppConstants.UI.cornerRadius))
            } else {
                emptyChartPlaceholder
            }
        }
    }

    private var emptyChartPlaceholder: some View {
        RoundedRectangle(cornerRadius: AppConstants.UI.cornerRadius)
            .fill(Color(.systemBackground))
            .frame(height: 160)
            .overlay {
                VStack(spacing: 8) {
                    Image(systemName: "chart.bar.fill")
                        .font(.title)
                        .foregroundStyle(Theme.primary.opacity(0.5))
                    Text("Start tracking to see your weekly trends")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
    }

    // MARK: - Category Breakdown Section

    private var categoryBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Breakdown")
                .font(.headline)

            if let breakdown = viewModel?.categoryBreakdown, !breakdown.isEmpty {
                VStack(spacing: 8) {
                    ForEach(breakdown.prefix(4)) { item in
                        CategoryBreakdownRow(item: item, totalMinutes: viewModel?.todayTotalMinutes ?? 1)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: AppConstants.UI.cornerRadius))
            } else {
                emptyBreakdownPlaceholder
            }
        }
    }

    private var emptyBreakdownPlaceholder: some View {
        RoundedRectangle(cornerRadius: AppConstants.UI.cornerRadius)
            .fill(Color(.systemBackground))
            .frame(height: 100)
            .overlay {
                VStack(spacing: 8) {
                    Image(systemName: "chart.pie.fill")
                        .font(.title)
                        .foregroundStyle(Theme.primary.opacity(0.5))
                    Text("Your time breakdown will appear here")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
    }

    // MARK: - Recent Activities Section

    private var recentActivitiesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Activities")
                    .font(.headline)
                Spacer()
                NavigationLink("See All") {
                    ActivitiesView()
                }
                .font(.subheadline)
                .foregroundStyle(Theme.primary)
            }

            if recentActivities.isEmpty {
                emptyStateView
            } else {
                ForEach(recentActivities.prefix(5)) { activity in
                    ActivityRowView(activity: activity)
                }
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "clock.badge.questionmark")
                .font(.system(size: 40))
                .foregroundStyle(Theme.primary.opacity(0.5))
            Text("No activities yet")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button("Log your first activity") {
                showingAddActivity = true
            }
            .font(.subheadline)
            .foregroundStyle(Theme.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: AppConstants.UI.cornerRadius))
    }
}

// MARK: - Stat Card Component

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Spacer()
            }

            Text(value)
                .font(.title2)
                .fontWeight(.bold)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: AppConstants.UI.cornerRadius))
    }
}

// MARK: - Activity Row Component

struct ActivityRowView: View {
    let activity: Activity

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Theme.primary.opacity(0.15))
                .frame(width: 40, height: 40)
                .overlay {
                    Image(systemName: activity.source.icon)
                        .foregroundStyle(Theme.primary)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(activity.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(activity.formattedTimeRange)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(activity.formattedDuration)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(Theme.primary)

                if activity.isOngoing {
                    HStack(spacing: 2) {
                        Circle()
                            .fill(Theme.success)
                            .frame(width: 6, height: 6)
                        Text("Active")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: AppConstants.UI.cornerRadius))
    }
}

// MARK: - Category Breakdown Row

struct CategoryBreakdownRow: View {
    let item: CategoryBreakdownItem
    let totalMinutes: Int

    private var percentage: Double {
        guard totalMinutes > 0 else { return 0 }
        return Double(item.minutes) / Double(totalMinutes)
    }

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text(item.name)
                    .font(.subheadline)
                Spacer()
                Text(item.formattedDuration)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(Theme.primary)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Theme.primary.gradient)
                        .frame(width: geometry.size.width * percentage, height: 6)
                }
            }
            .frame(height: 6)
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(AppState())
        .modelContainer(for: [Activity.self, Tag.self, PomodoroSession.self])
}
