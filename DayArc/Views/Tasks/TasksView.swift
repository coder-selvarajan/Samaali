//
//  TasksView.swift
//  DayArc
//
//  Created by Claude Code on 2/2/26.
//

import SwiftUI
import SwiftData

struct TasksView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appState: AppState
    @Query(sort: \UserTask.createdAt, order: .reverse)
    private var tasks: [UserTask]

    @State private var showingAddTask = false
    @State private var filterCompleted = false

    private let calendar = Calendar.current

    private var startOfToday: Date { calendar.startOfDay(for: Date()) }

    // MARK: - Task Groups

    private var pendingTasks: [UserTask] { tasks.filter { !$0.isCompleted } }

    private var overdueTasks: [UserTask] {
        pendingTasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return dueDate < startOfToday
        }.sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
    }

    private var todayTasks: [UserTask] {
        pendingTasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return calendar.isDateInToday(dueDate)
        }.sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
    }

    private var laterTasks: [UserTask] {
        pendingTasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return dueDate >= calendar.date(byAdding: .day, value: 1, to: startOfToday)!
        }.sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
    }

    private var noDateTasks: [UserTask] {
        pendingTasks.filter { $0.dueDate == nil }
            .sorted { $0.createdAt > $1.createdAt }
    }

    private var completedTasks: [UserTask] {
        tasks.filter { $0.isCompleted }
            .sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
    }

    private var hasVisibleTasks: Bool {
        !overdueTasks.isEmpty || !todayTasks.isEmpty || !laterTasks.isEmpty
            || !noDateTasks.isEmpty || (filterCompleted && !completedTasks.isEmpty)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Group {
                if tasks.isEmpty {
                    emptyStateView
                } else if !hasVisibleTasks {
                    allDoneView
                } else {
                    taskListView
                }
            }
            .navigationTitle("Tasks")
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
                        showingAddTask = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(Theme.primary)
                    }
                }
                ToolbarItem(placement: .secondaryAction) {
                    Menu {
                        Toggle("Show Completed", isOn: $filterCompleted)
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .sheet(isPresented: $showingAddTask) {
                AddTaskView()
            }
        }
    }

    // MARK: - Sub Views

    private var emptyStateView: some View {
        ContentUnavailableView(
            "No Tasks",
            systemImage: "checklist",
            description: Text("Add tasks to track what you need to do.")
        )
    }

    private var allDoneView: some View {
        ContentUnavailableView(
            "All Done!",
            systemImage: "checkmark.circle.fill",
            description: Text("All tasks completed. Enable 'Show Completed' to review them.")
        )
    }

    private var taskListView: some View {
        List {
            if !overdueTasks.isEmpty {
                Section {
                    ForEach(overdueTasks) { task in TaskRowView(task: task) }
                        .onDelete { deleteTasksFrom(overdueTasks, at: $0) }
                } header: {
                    taskSectionHeader(title: "Overdue", systemImage: "exclamationmark.circle.fill", color: .red)
                }
            }

            if !todayTasks.isEmpty {
                Section {
                    ForEach(todayTasks) { task in TaskRowView(task: task) }
                        .onDelete { deleteTasksFrom(todayTasks, at: $0) }
                } header: {
                    taskSectionHeader(title: "Today", systemImage: "sun.max.fill", color: .orange)
                }
            }

            if !laterTasks.isEmpty {
                Section {
                    ForEach(laterTasks) { task in TaskRowView(task: task) }
                        .onDelete { deleteTasksFrom(laterTasks, at: $0) }
                } header: {
                    taskSectionHeader(title: "Later", systemImage: "calendar", color: Theme.primary)
                }
            }

            if !noDateTasks.isEmpty {
                Section {
                    ForEach(noDateTasks) { task in TaskRowView(task: task) }
                        .onDelete { deleteTasksFrom(noDateTasks, at: $0) }
                } header: {
                    taskSectionHeader(title: "No Date", systemImage: "tray", color: .secondary)
                }
            }

            if filterCompleted && !completedTasks.isEmpty {
                Section {
                    ForEach(completedTasks) { task in TaskRowView(task: task) }
                        .onDelete { deleteTasksFrom(completedTasks, at: $0) }
                } header: {
                    taskSectionHeader(title: "Completed", systemImage: "checkmark.circle.fill", color: Theme.success)
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private func taskSectionHeader(title: String, systemImage: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .foregroundStyle(color)
            Text(title)
                .fontWeight(.semibold)
        }
    }

    private func deleteTasksFrom(_ taskGroup: [UserTask], at offsets: IndexSet) {
        for index in offsets {
            let task = taskGroup[index]
            NotificationService.shared.cancelTaskReminder(taskId: task.id)
            modelContext.delete(task)
        }
    }
}

// MARK: - Task Row View

struct TaskRowView: View {
    @Bindable var task: UserTask

    var body: some View {
        HStack(spacing: 12) {
            Button {
                withAnimation {
                    task.isCompleted.toggle()
                    if task.isCompleted {
                        task.completedAt = Date()
                        if task.reminderDate != nil {
                            NotificationService.shared.cancelTaskReminder(taskId: task.id)
                        }
                    } else {
                        task.completedAt = nil
                        if let reminderDate = task.reminderDate, reminderDate > Date() {
                            NotificationService.shared.scheduleTaskReminder(task: task)
                        }
                    }
                }
            } label: {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(task.isCompleted ? Theme.success : .secondary)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .strikethrough(task.isCompleted)
                    .foregroundStyle(task.isCompleted ? .secondary : .primary)

                if let dueDate = task.dueDate {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                        Text(dueDate, style: .date)
                        Text("·")
                        Text(dueDate, style: .time)
                    }
                    .font(.caption)
                    .foregroundStyle(isOverdue(dueDate) ? .red : .secondary)
                }
            }

            Spacer()

            HStack(spacing: 8) {
                if task.reminderDate != nil {
                    Image(systemName: "bell.fill")
                        .font(.caption)
                        .foregroundStyle(Theme.primary)
                }
                priorityIndicator
            }
        }
        .padding(.vertical, 4)
    }

    private var priorityIndicator: some View {
        Image(systemName: task.priority.icon)
            .font(.caption)
            .foregroundStyle(priorityColor)
    }

    private var priorityColor: Color {
        switch task.priority {
        case .low: return Theme.primary
        case .medium: return Theme.warning
        case .high: return Theme.error
        }
    }

    private func isOverdue(_ date: Date) -> Bool {
        !task.isCompleted && date < Date()
    }
}

// MARK: - Add Task View

struct AddTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var title = ""
    @State private var notes = ""
    @State private var hasDueDate = false
    @State private var dueDate = Date()
    @State private var hasReminder = false
    @State private var priority: TaskPriority = .medium

    var body: some View {
        NavigationStack {
            Form {
                Section("Task Details") {
                    TextField("What needs to be done?", text: $title)
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Due Date") {
                    Toggle("Set Due Date", isOn: $hasDueDate)
                        .onChange(of: hasDueDate) { _, newValue in
                            if !newValue { hasReminder = false }
                        }
                    if hasDueDate {
                        DatePicker("Due", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                        Toggle(isOn: $hasReminder) {
                            Label("Remind me at due time", systemImage: "bell")
                        }
                        .onChange(of: hasReminder) { _, newValue in
                            if newValue {
                                Task {
                                    try? await NotificationService.shared.requestAuthorization()
                                }
                            }
                        }
                    }
                }

                Section("Priority") {
                    Picker("Priority", selection: $priority) {
                        ForEach(TaskPriority.allCases, id: \.self) { priority in
                            Label(priority.title, systemImage: priority.icon)
                                .tag(priority)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        saveTask()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(Theme.primary)
                    .disabled(title.isEmpty)
                }
            }
        }
    }

    private func saveTask() {
        let reminderDate = (hasDueDate && hasReminder) ? dueDate : nil
        let task = UserTask(
            title: title,
            notes: notes.isEmpty ? nil : notes,
            dueDate: hasDueDate ? dueDate : nil,
            reminderDate: reminderDate,
            priority: priority
        )
        modelContext.insert(task)

        if hasDueDate && hasReminder {
            NotificationService.shared.scheduleTaskReminder(task: task)
        }

        dismiss()
    }
}

#Preview {
    TasksView()
        .modelContainer(for: [UserTask.self, Tag.self])
}
