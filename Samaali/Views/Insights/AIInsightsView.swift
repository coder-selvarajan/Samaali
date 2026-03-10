//
//  AIInsightsView.swift
//  Samaali
//
//  Created by Claude Code on 2/6/26.
//

import SwiftUI
import SwiftData
import Charts

struct AIInsightsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: AIInsightsViewModel?

    var body: some View {
        NavigationStack {
            Group {
                if let vm = viewModel {
                    AIInsightsContentView(viewModel: vm)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("AI Insights")
            .onAppear {
                if viewModel == nil {
                    viewModel = AIInsightsViewModel(modelContext: modelContext)
                }
            }
        }
    }
}

// MARK: - Content View

struct AIInsightsContentView: View {
    @Bindable var viewModel: AIInsightsViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if !viewModel.isEnabled {
                    disabledCard
                } else {
                    weeklySummaryCard
                    streakCard
                    productivityTrendCard
                    insightsListCard
                    analyzeCard
                }
            }
            .padding()
        }
        .refreshable {
            await viewModel.refreshAll()
        }
        .alert("Insights Error", isPresented: $viewModel.showError) {
            Button("OK") { viewModel.showError = false }
        } message: {
            Text(viewModel.error?.localizedDescription ?? "An unknown error occurred")
        }
        .task {
            if viewModel.isEnabled {
                await viewModel.refreshAll()
            }
        }
    }

    // MARK: - Disabled Card

    private var disabledCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 60))
                .foregroundStyle(Theme.primary)

            Text("AI Insights Disabled")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Enable AI insights to get personalized productivity analysis, pattern detection, and recommendations based on your activity data.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: 8) {
                FeatureRowInsights(icon: "lock.shield", text: "100% on-device processing")
                FeatureRowInsights(icon: "chart.bar.xaxis", text: "Productivity patterns")
                FeatureRowInsights(icon: "lightbulb", text: "Smart recommendations")
            }
            .padding(.vertical)

            Button {
                viewModel.isEnabled = true
                Task { await viewModel.refreshAll() }
            } label: {
                Text("Enable AI Insights")
            }
            .buttonStyle(.primary)
        }
        .padding(24)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: AppConstants.UI.cornerRadius))
        .shadow(color: Theme.cardShadow, radius: AppConstants.UI.shadowRadius)
    }

    // MARK: - Weekly Summary Card

    private var weeklySummaryCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("This Week")
                    .font(.headline)
                Spacer()
                if viewModel.isLoading {
                    ProgressView()
                }
            }

            if let summary = viewModel.weeklySummary {
                HStack(spacing: 16) {
                    SummaryStatView(
                        title: "Total Time",
                        value: summary.formattedTotalTime,
                        icon: "clock.fill",
                        color: Theme.primary
                    )

                    SummaryStatView(
                        title: "Productive",
                        value: summary.formattedProductiveTime,
                        icon: "bolt.fill",
                        color: Theme.success
                    )

                    SummaryStatView(
                        title: "Active Days",
                        value: "\(summary.activeDays)",
                        icon: "calendar",
                        color: Theme.accent
                    )
                }

                Divider()

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Avg. Productivity")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(viewModel.averageProductivityLabel)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundStyle(productivityColor(for: summary.averageProductivityScore))
                    }

                    Spacer()

                    if let topCategory = summary.topCategory {
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Top Category")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(topCategory)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                    }
                }
            } else {
                Text("Loading summary...")
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: AppConstants.UI.cornerRadius))
        .shadow(color: Theme.cardShadow, radius: AppConstants.UI.shadowRadius)
    }

    // MARK: - Streak Card

    private var streakCard: some View {
        HStack(spacing: 16) {
            Image(systemName: "flame.fill")
                .font(.system(size: 40))
                .foregroundStyle(.orange)

            VStack(alignment: .leading, spacing: 4) {
                Text("Current Streak")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(viewModel.currentStreakLabel)
                    .font(.title2)
                    .fontWeight(.bold)
            }

            Spacer()

            if let streak = viewModel.streakInfo {
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Best")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(streak.longestStreak) days")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
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

    // MARK: - Productivity Trend Card

    private var productivityTrendCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Productivity Trend")
                .font(.headline)

            if !viewModel.productivityTrend.isEmpty {
                Chart(viewModel.productivityTrend) { point in
                    LineMark(
                        x: .value("Day", point.date, unit: .day),
                        y: .value("Score", point.score * 100)
                    )
                    .foregroundStyle(Theme.primaryGradient)
                    .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))

                    AreaMark(
                        x: .value("Day", point.date, unit: .day),
                        y: .value("Score", point.score * 100)
                    )
                    .foregroundStyle(Theme.primary.opacity(0.1))

                    PointMark(
                        x: .value("Day", point.date, unit: .day),
                        y: .value("Score", point.score * 100)
                    )
                    .foregroundStyle(Theme.primary)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { value in
                        AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let score = value.as(Double.self) {
                                Text("\(Int(score))%")
                            }
                        }
                    }
                }
                .chartYScale(domain: 0...100)
                .frame(height: 180)
            } else {
                Text("Not enough data yet")
                    .foregroundStyle(.secondary)
                    .frame(height: 180)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: AppConstants.UI.cornerRadius))
        .shadow(color: Theme.cardShadow, radius: AppConstants.UI.shadowRadius)
    }

    // MARK: - Insights List Card

    private var insightsListCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Insights")
                    .font(.headline)
                Spacer()
                if let lastRefresh = viewModel.formattedLastRefresh {
                    Text("Updated \(lastRefresh)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if viewModel.insights.isEmpty {
                emptyInsightsView
            } else {
                ForEach(viewModel.insights) { insight in
                    InsightRowView(insight: insight)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: AppConstants.UI.cornerRadius))
        .shadow(color: Theme.cardShadow, radius: AppConstants.UI.shadowRadius)
    }

    private var emptyInsightsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("No insights yet")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("Keep tracking activities to generate personalized insights")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    // MARK: - Analyze Card

    private var analyzeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Activity Analysis")
                        .font(.headline)
                    Text("Analyze unreviewed activities for better insights")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            Button {
                Task { await viewModel.analyzeAllActivities() }
            } label: {
                HStack {
                    if viewModel.isAnalyzing {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "wand.and.stars")
                    }
                    Text(viewModel.isAnalyzing ? "Analyzing..." : "Analyze Activities")
                }
            }
            .buttonStyle(.primary)
            .disabled(viewModel.isAnalyzing)

            if viewModel.analyzedCount > 0 {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Theme.success)
                    Text("\(viewModel.analyzedCount) activities analyzed")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: AppConstants.UI.cornerRadius))
        .shadow(color: Theme.cardShadow, radius: AppConstants.UI.shadowRadius)
    }

    // MARK: - Helpers

    private func productivityColor(for score: Double) -> Color {
        switch score {
        case 0..<0.3: return .red
        case 0.3..<0.6: return .orange
        case 0.6..<0.8: return .blue
        default: return .green
        }
    }
}

// MARK: - Supporting Views

private struct FeatureRowInsights: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Theme.primary)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
        }
    }
}

private struct SummaryStatView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)

            Text(value)
                .font(.headline)
                .fontWeight(.semibold)

            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct InsightRowView: View {
    let insight: Insight

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: insight.type.icon)
                .font(.title3)
                .foregroundStyle(insight.type.color)
                .frame(width: 32, height: 32)
                .background(insight.type.backgroundColor)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(insight.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(insight.message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }

            Spacer()
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Compact Insight Card (for Home)

struct CompactInsightCard: View {
    let insight: Insight

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: insight.type.icon)
                .font(.title2)
                .foregroundStyle(insight.type.color)

            VStack(alignment: .leading, spacing: 2) {
                Text(insight.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(insight.message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(insight.type.backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: AppConstants.UI.cornerRadius))
    }
}

// MARK: - Preview

#Preview {
    AIInsightsView()
        .modelContainer(for: [Activity.self, Tag.self])
}
