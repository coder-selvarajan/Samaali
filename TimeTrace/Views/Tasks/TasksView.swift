//
//  TasksView.swift
//  TimeTrace
//
//  Created by Claude Code on 2/2/26.
//

import SwiftUI
import SwiftData

struct TasksView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \UserTask.createdAt, order: .reverse)
    private var tasks: [UserTask]

    @State private var showingAddTask = false
    @State private var filterCompleted = false

    var body: some View {
        NavigationStack {
            Group {
                if tasks.isEmpty {
                    emptyStateView
                } else {
                    taskListView
                }
            }
            .navigationTitle("Tasks")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddTask = true
                    } label: {
                        Image(systemName: "plus")
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

    private var filteredTasks: [UserTask] {
        if filterCompleted {
            return tasks
        }
        return tasks.filter { !$0.isCompleted }
    }

    private var emptyStateView: some View {
        ContentUnavailableView(
            "No Tasks",
            systemImage: "checklist",
            description: Text("Add tasks to track what you need to do.")
        )
    }

    private var taskListView: some View {
        List {
            ForEach(filteredTasks) { task in
                TaskRowView(task: task)
            }
            .onDelete(perform: deleteTasks)
        }
        .listStyle(.insetGrouped)
    }

    private func deleteTasks(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(filteredTasks[index])
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
                    } else {
                        task.completedAt = nil
                    }
                }
            } label: {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(task.isCompleted ? .green : .secondary)
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
                    }
                    .font(.caption)
                    .foregroundStyle(isOverdue(dueDate) ? .red : .secondary)
                }
            }

            Spacer()

            priorityIndicator
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
        case .low: return .blue
        case .medium: return .orange
        case .high: return .red
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
                    if hasDueDate {
                        DatePicker("Due", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
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
                    .disabled(title.isEmpty)
                }
            }
        }
    }

    private func saveTask() {
        let task = UserTask(
            title: title,
            notes: notes.isEmpty ? nil : notes,
            dueDate: hasDueDate ? dueDate : nil,
            priority: priority
        )
        modelContext.insert(task)
        dismiss()
    }
}

#Preview {
    TasksView()
        .modelContainer(for: [UserTask.self, Tag.self])
}
