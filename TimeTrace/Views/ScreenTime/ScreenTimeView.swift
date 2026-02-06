//
//  ScreenTimeView.swift
//  TimeTrace
//
//  Created by Claude Code on 2/6/26.
//

import SwiftUI
import SwiftData
import Charts

struct ScreenTimeView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: ScreenTimeViewModel?

    var body: some View {
        NavigationStack {
            Group {
                if let vm = viewModel {
                    ScreenTimeContentView(viewModel: vm)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Screen Time")
            .onAppear {
                if viewModel == nil {
                    viewModel = ScreenTimeViewModel(modelContext: modelContext)
                }
            }
        }
    }
}

// MARK: - Content View

struct ScreenTimeContentView: View {
    @Bindable var viewModel: ScreenTimeViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if !viewModel.isAuthorized {
                    authorizationCard
                } else {
                    todaySummaryCard
                    categoryBreakdownCard
                    importCard
                    weeklyTrendCard
                }
            }
            .padding()
        }
        .refreshable {
            await viewModel.loadTodaySummary()
        }
        .alert("Screen Time Error", isPresented: $viewModel.showError) {
            Button("OK") { viewModel.showError = false }
        } message: {
            Text(viewModel.error?.errorDescription ?? "An unknown error occurred")
        }
        .task {
            if viewModel.isAuthorized {
                await viewModel.loadTodaySummary()
                await viewModel.loadWeekSummaries()
            }
        }
    }

    // MARK: - Authorization Card

    private var authorizationCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "hourglass.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(Theme.primary)

            Text("Screen Time Access")
                .font(.title2)
                .fontWeight(.semibold)

            Text("TimeTrace can import your Screen Time data to automatically track app usage and help you understand your digital habits.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: 8) {
                FeatureRow(icon: "lock.shield", text: "Data stays on your device")
                FeatureRow(icon: "chart.pie", text: "See usage by category")
                FeatureRow(icon: "arrow.down.circle", text: "Import as activities")
            }
            .padding(.vertical)

            Button {
                Task {
                    await viewModel.requestAuthorization()
                }
            } label: {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Enable Screen Time Access")
                }
            }
            .buttonStyle(.primary)
            .disabled(viewModel.isLoading)

            if viewModel.authorizationStatus == .denied {
                Text("Access was denied. Please enable Screen Time access in Settings > Privacy > Screen Time.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(24)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: AppConstants.UI.cornerRadius))
        .shadow(color: Theme.cardShadow, radius: AppConstants.UI.shadowRadius)
    }

    // MARK: - Today Summary Card

    private var todaySummaryCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Today")
                    .font(.headline)
                Spacer()
                if viewModel.isLoading {
                    ProgressView()
                }
            }

            if let summary = viewModel.todaySummary {
                HStack(spacing: 24) {
                    StatItem(
                        title: "Total Time",
                        value: viewModel.formattedTotalTime,
                        icon: "clock.fill",
                        color: Theme.primary
                    )

                    StatItem(
                        title: "Pickups",
                        value: "\(summary.pickupCount)",
                        icon: "hand.tap.fill",
                        color: Theme.accent
                    )

                    StatItem(
                        title: "Productive",
                        value: "\(Int(viewModel.productiveTimePercentage * 100))%",
                        icon: "bolt.fill",
                        color: Theme.success
                    )
                }

                if let firstPickup = summary.firstPickupTime {
                    HStack {
                        Image(systemName: "sunrise.fill")
                            .foregroundStyle(.orange)
                        Text("First pickup: \(firstPickup.formatted(date: .omitted, time: .shortened))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                Text("No data available")
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: AppConstants.UI.cornerRadius))
        .shadow(color: Theme.cardShadow, radius: AppConstants.UI.shadowRadius)
    }

    // MARK: - Category Breakdown Card

    private var categoryBreakdownCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Usage by Category")
                .font(.headline)

            if let summary = viewModel.todaySummary {
                // Pie Chart
                Chart(summary.categoryUsages, id: \.categoryName) { usage in
                    SectorMark(
                        angle: .value("Minutes", usage.durationMinutes),
                        innerRadius: .ratio(0.5),
                        angularInset: 1
                    )
                    .foregroundStyle(Color(hex: usage.category.colorHex) ?? .gray)
                    .cornerRadius(4)
                }
                .frame(height: 180)

                // Legend
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(summary.categoryUsages, id: \.categoryName) { usage in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color(hex: usage.category.colorHex) ?? .gray)
                                .frame(width: 10, height: 10)
                            Text(usage.categoryName)
                                .font(.caption)
                                .lineLimit(1)
                            Spacer()
                            Text(formatMinutes(usage.durationMinutes))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: AppConstants.UI.cornerRadius))
        .shadow(color: Theme.cardShadow, radius: AppConstants.UI.shadowRadius)
    }

    // MARK: - Import Card

    private var importCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Import as Activities")
                        .font(.headline)
                    Text("Convert Screen Time data to activities for tracking")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            Button {
                Task {
                    await viewModel.importTodayAsActivities()
                }
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.down")
                    Text(viewModel.isImporting ? "Importing..." : "Import Today's Data")
                }
            }
            .buttonStyle(.secondary)
            .disabled(!viewModel.canImport)

            if viewModel.importCount > 0 {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Theme.success)
                    Text("\(viewModel.importCount) activities imported")
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

    // MARK: - Weekly Trend Card

    private var weeklyTrendCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Weekly Trend")
                .font(.headline)

            if !viewModel.weekSummaries.isEmpty {
                Chart(viewModel.weekSummaries, id: \.date) { summary in
                    BarMark(
                        x: .value("Day", summary.date, unit: .day),
                        y: .value("Hours", Double(summary.totalMinutes) / 60.0)
                    )
                    .foregroundStyle(Theme.primaryGradient)
                    .cornerRadius(4)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { value in
                        AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let hours = value.as(Double.self) {
                                Text("\(Int(hours))h")
                            }
                        }
                    }
                }
                .frame(height: 150)
            } else {
                Text("Loading...")
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: AppConstants.UI.cornerRadius))
        .shadow(color: Theme.cardShadow, radius: AppConstants.UI.shadowRadius)
    }

    // MARK: - Helpers

    private func formatMinutes(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        if hours > 0 {
            return "\(hours)h \(mins)m"
        }
        return "\(mins)m"
    }
}

// MARK: - Supporting Views

private struct FeatureRow: View {
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

private struct StatItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)

            Text(value)
                .font(.title3)
                .fontWeight(.semibold)

            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

#Preview {
    ScreenTimeView()
        .modelContainer(for: [Activity.self, Tag.self])
}
