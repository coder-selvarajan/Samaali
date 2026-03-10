//
//  HabitsView.swift
//  Samaali
//
//  Created by Claude Code on 3/8/26.
//

import SwiftUI
import SwiftData

struct HabitsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appState: AppState
    @Query(filter: #Predicate<Habit> { !$0.isArchived },
           sort: \Habit.createdAt)
    private var habits: [Habit]

    @State private var showingAddHabit = false
    @State private var selectedDate = Date()
    @State private var showArchived = false

    private let calendar = Calendar.current

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Group {
                if habits.isEmpty {
                    emptyStateView
                } else {
                    habitListView
                }
            }
            .navigationTitle("Habits")
            .toolbarTitleDisplayMode(.inlineLarge)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddHabit = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(Theme.primary)
                    }
                }
            }
            .sheet(isPresented: $showingAddHabit) {
                AddHabitView()
            }
        }
    }

    // MARK: - Sub Views

    private var emptyStateView: some View {
        ContentUnavailableView(
            "No Habits",
            systemImage: "repeat.circle",
            description: Text("Add habits you want to build and track them daily.")
        )
    }

    private var habitListView: some View {
        List {
            // Date navigation
            Section {
                dateNavigationView
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())
            .listSectionSpacing(0)

            // Week overview
            Section {
                weekOverviewView
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())

            // Habits for selected date
            Section {
                ForEach(habits) { habit in
                    HabitRowView(habit: habit, date: selectedDate) {
                        toggleHabit(habit)
                    }
                }
                .onDelete(perform: deleteHabits)
            } header: {
                HStack(spacing: 6) {
                    Image(systemName: "list.bullet")
                        .foregroundStyle(Theme.primary)
                    Text(calendar.isDateInToday(selectedDate) ? "Today's Habits" : formattedDate)
                        .fontWeight(.semibold)
                }
            }
        }
        .listStyle(.insetGrouped)
        .listSectionSpacing(.compact)
        .contentMargins(.top, 0)
    }

    private var dateNavigationView: some View {
        HStack {
            Button {
                withAnimation {
                    selectedDate = calendar.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .foregroundStyle(Theme.primary)
            }

            Spacer()

            VStack(spacing: 2) {
                Text(selectedDate, format: .dateTime.weekday(.wide))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(selectedDate, format: .dateTime.month().day())
                    .font(.title3)
                    .fontWeight(.bold)
            }
            .onTapGesture {
                withAnimation { selectedDate = Date() }
            }

            Spacer()

            Button {
                withAnimation {
                    let tomorrow = calendar.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
                    if tomorrow <= Date() {
                        selectedDate = tomorrow
                    }
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .foregroundStyle(isFutureDate ? .secondary.opacity(0.3) : Theme.primary)
            }
            .disabled(isFutureDate)
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
    }

    private var weekOverviewView: some View {
        HStack(spacing: 4) {
            ForEach(weekDays, id: \.self) { day in
                let completedCount = habits.filter { $0.isCompletedOn(day) }.count
                let ratio = habits.isEmpty ? 0.0 : Double(completedCount) / Double(habits.count)
                let isSelected = calendar.isDate(day, inSameDayAs: selectedDate)

                VStack(spacing: 4) {
                    Text(day, format: .dateTime.weekday(.narrow))
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    ZStack {
                        Circle()
                            .fill(isSelected ? Theme.primary.opacity(0.15) : Color.clear)
                            .frame(width: 36, height: 36)

                        Circle()
                            .trim(from: 0, to: ratio)
                            .stroke(Theme.primary, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                            .frame(width: 28, height: 28)
                            .rotationEffect(.degrees(-90))

                        if ratio == 1.0 {
                            Image(systemName: "checkmark")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundStyle(Theme.primary)
                        } else {
                            Text(day, format: .dateTime.day())
                                .font(.caption2)
                                .fontWeight(isSelected ? .bold : .regular)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .onTapGesture {
                    if day <= Date() {
                        withAnimation { selectedDate = day }
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    // MARK: - Helpers

    private var isFutureDate: Bool {
        calendar.startOfDay(for: selectedDate) >= calendar.startOfDay(for: Date())
    }

    private var formattedDate: String {
        selectedDate.formatted(date: .abbreviated, time: .omitted)
    }

    private var weekDays: [Date] {
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: selectedDate)) ?? selectedDate
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: startOfWeek) }
    }

    private func toggleHabit(_ habit: Habit) {
        withAnimation {
            let service = HabitService(modelContext: modelContext)
            service.toggleHabit(habit, for: selectedDate)
        }
    }

    private func deleteHabits(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(habits[index])
        }
    }
}

// MARK: - Habit Row View

struct HabitRowView: View {
    let habit: Habit
    let date: Date
    let onToggle: () -> Void

    private var isCompleted: Bool { habit.isCompletedOn(date) }

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isCompleted ? Color(hex: habit.colorHex) ?? Theme.primary : .secondary)
            }
            .buttonStyle(.plain)

            Image(systemName: habit.icon)
                .font(.body)
                .foregroundStyle(Color(hex: habit.colorHex) ?? Theme.primary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(habit.name)
                    .foregroundStyle(isCompleted ? .secondary : .primary)

                if habit.currentStreak > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                        Text("\(habit.currentStreak) day streak")
                    }
                    .font(.caption)
                    .foregroundStyle(.orange)
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}

// MARK: - Add Habit View

struct AddHabitView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var name = ""
    @State private var selectedIcon = "checkmark.circle"
    @State private var selectedColor = "#5856D6"

    private let icons = [
        "checkmark.circle", "star.fill", "heart.fill", "bolt.fill",
        "book.fill", "figure.run", "drop.fill", "moon.fill",
        "sun.max.fill", "leaf.fill", "brain.head.profile", "dumbbell.fill",
        "cup.and.saucer.fill", "pencil", "music.note", "paintbrush.fill"
    ]

    private let colors = [
        "#5856D6", "#AF52DE", "#FF2D55", "#FF9500",
        "#FFCC00", "#34C759", "#00C7BE", "#5AC8FA",
        "#007AFF", "#FF6482"
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Habit Details") {
                    TextField("Habit name", text: $name)
                }

                Section("Icon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 12) {
                        ForEach(icons, id: \.self) { icon in
                            Image(systemName: icon)
                                .font(.title3)
                                .frame(width: 36, height: 36)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(selectedIcon == icon ? (Color(hex: selectedColor) ?? Theme.primary).opacity(0.2) : Color.clear)
                                )
                                .foregroundStyle(selectedIcon == icon ? (Color(hex: selectedColor) ?? Theme.primary) : .secondary)
                                .onTapGesture { selectedIcon = icon }
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                        ForEach(colors, id: \.self) { color in
                            Circle()
                                .fill(Color(hex: color) ?? .gray)
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Circle()
                                        .stroke(Color.primary, lineWidth: selectedColor == color ? 2 : 0)
                                        .padding(2)
                                )
                                .onTapGesture { selectedColor = color }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("New Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        saveHabit()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(Theme.primary)
                    .disabled(name.isEmpty)
                }
            }
        }
    }

    private func saveHabit() {
        let service = HabitService(modelContext: modelContext)
        service.createHabit(name: name, icon: selectedIcon, colorHex: selectedColor)
        dismiss()
    }
}

#Preview {
    HabitsView()
        .modelContainer(for: [Habit.self, HabitLog.self])
        .environmentObject(AppState())
}
