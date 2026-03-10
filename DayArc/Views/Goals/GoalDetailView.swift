//
//  GoalDetailView.swift
//  DayArc
//
//  Created by Claude Code on 2/6/26.
//

import SwiftUI
import SwiftData
import PhotosUI

struct GoalDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var goal: Goal

    @State private var showingEditGoal = false
    @State private var showingDeleteAlert = false
    @State private var newComment = ""
    @FocusState private var isCommentFocused: Bool

    private var goalColor: Color {
        Color(hex: goal.colorHex) ?? Theme.primary
    }

    private let headerTextColor = Color(red: 0.2, green: 0.2, blue: 0.25)
    private let headerTextSecondary = Color(red: 0.35, green: 0.35, blue: 0.4)

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header with image/color
                headerSection

                // Content
                VStack(spacing: 24) {
                    // Status and Progress Card
                    statusCard

                    // Timeline Card
                    timelineCard

                    // Description Card
                    if !goal.goalDescription.isEmpty {
                        descriptionCard
                    }

                    // Comments Section
                    commentsSection
                }
                .padding()
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        showingEditGoal = true
                    } label: {
                        Label("Edit Goal", systemImage: "pencil")
                    }

                    Divider()

                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        Label("Delete Goal", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingEditGoal) {
            EditGoalView(goal: goal)
        }
        .alert("Delete Goal", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteGoal()
            }
        } message: {
            Text("Are you sure you want to delete this goal? This action cannot be undone.")
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        ZStack(alignment: .bottomLeading) {
            // Background
            if let imageData = goal.imageData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 200)
                    .clipped()
                    .overlay {
                        LinearGradient(
                            colors: [.clear, .black.opacity(0.6)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
            } else {
                LinearGradient(
                    colors: [goalColor, goalColor.opacity(0.7)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(height: 200)
            }

            // Title overlay
            VStack(alignment: .leading, spacing: 8) {
                if let icon = goal.icon {
                    Image(systemName: icon)
                        .font(.title)
                        .foregroundStyle(goal.imageData != nil ? .white : headerTextColor)
                }

                Text(goal.title)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(goal.imageData != nil ? .white : headerTextColor)

                HStack(spacing: 8) {
                    Image(systemName: goal.status.icon)
                    Text(goal.status.title)
                        .font(.subheadline)
                }
                .foregroundStyle(goal.imageData != nil ? .white.opacity(0.9) : headerTextSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(goal.imageData != nil ? .white.opacity(0.2) : headerTextColor.opacity(0.1))
                .clipShape(Capsule())
            }
            .padding()
        }
    }

    // MARK: - Status Card
    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Progress")
                .font(.headline)

            // Progress bar
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("\(goal.progressPercentage)% Complete")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    if goal.milestones > 0 {
                        Text("\(goal.completedMilestones)/\(goal.milestones) milestones")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(.systemGray5))
                            .frame(height: 12)

                        RoundedRectangle(cornerRadius: 6)
                            .fill(goalColor)
                            .frame(width: geometry.size.width * goal.progress, height: 12)
                    }
                }
                .frame(height: 12)
            }

            // Quick progress buttons
            HStack(spacing: 12) {
                ForEach([0.0, 0.25, 0.5, 0.75, 1.0], id: \.self) { value in
                    Button {
                        withAnimation {
                            goal.progress = value
                            goal.updatedAt = Date()
                            if value == 1.0 {
                                goal.status = .completed
                            } else if value > 0 && goal.status == .notStarted {
                                goal.status = .inProgress
                            }
                        }
                    } label: {
                        Text("\(Int(value * 100))%")
                            .font(.caption)
                            .fontWeight(goal.progress == value ? .semibold : .regular)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(goal.progress == value ? goalColor : Color(.systemGray5))
                            .foregroundStyle(goal.progress == value ? headerTextColor : .primary)
                            .clipShape(Capsule())
                    }
                }
            }

            Divider()

            // Status picker
            HStack {
                Text("Status")
                    .font(.subheadline)
                Spacer()
                Menu {
                    ForEach(GoalStatus.allCases, id: \.self) { status in
                        Button {
                            goal.status = status
                            goal.updatedAt = Date()
                        } label: {
                            Label(status.title, systemImage: status.icon)
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: goal.status.icon)
                        Text(goal.status.title)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption2)
                    }
                    .font(.subheadline)
                    .foregroundStyle(Color(hex: goal.status.colorHex) ?? .primary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: AppConstants.UI.cornerRadius))
    }

    // MARK: - Timeline Card
    private var timelineCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Timeline")
                .font(.headline)

            HStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Started")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(goal.formattedStartDate)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Target")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(goal.formattedTargetDate)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(goal.isOverdue ? Theme.error : .primary)
                }
            }

            if goal.targetDate != nil {
                HStack {
                    Image(systemName: goal.isOverdue ? "exclamationmark.triangle.fill" : "clock")
                        .foregroundStyle(goal.isOverdue ? Theme.error : goalColor)
                    Text(goal.timelineDescription)
                        .font(.subheadline)
                        .foregroundStyle(goal.isOverdue ? Theme.error : .secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: AppConstants.UI.cornerRadius))
    }

    // MARK: - Description Card
    private var descriptionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Description")
                .font(.headline)

            Text(goal.goalDescription)
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: AppConstants.UI.cornerRadius))
    }

    // MARK: - Comments Section
    private var commentsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Comments")
                    .font(.headline)
                Spacer()
                Text("\(goal.comments?.count ?? 0)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Add comment field
            HStack(spacing: 12) {
                TextField("Add a comment...", text: $newComment, axis: .vertical)
                    .textFieldStyle(.plain)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .focused($isCommentFocused)

                Button {
                    addComment()
                } label: {
                    Image(systemName: "paperplane.fill")
                        .font(.title3)
                        .foregroundStyle(newComment.isEmpty ? .gray : goalColor)
                }
                .disabled(newComment.isEmpty)
            }

            // Comments list
            if let comments = goal.comments, !comments.isEmpty {
                VStack(spacing: 12) {
                    ForEach(goal.sortedComments) { comment in
                        CommentRow(comment: comment, goalColor: goalColor) {
                            deleteComment(comment)
                        }
                    }
                }
            } else {
                Text("No comments yet. Add one to track your progress!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: AppConstants.UI.cornerRadius))
    }

    // MARK: - Actions
    private func addComment() {
        guard !newComment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        let comment = GoalComment(content: newComment, goal: goal)
        modelContext.insert(comment)

        if goal.comments == nil {
            goal.comments = []
        }
        goal.comments?.append(comment)
        goal.updatedAt = Date()

        newComment = ""
        isCommentFocused = false
    }

    private func deleteComment(_ comment: GoalComment) {
        goal.comments?.removeAll { $0.id == comment.id }
        modelContext.delete(comment)
    }

    private func deleteGoal() {
        modelContext.delete(goal)
        dismiss()
    }
}

// MARK: - Comment Row
struct CommentRow: View {
    let comment: GoalComment
    let goalColor: Color
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(comment.formattedDate)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Menu {
                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundStyle(.secondary)
                        .padding(8)
                }
            }

            Text(comment.content)
                .font(.body)
                .foregroundStyle(.primary)
        }
        .padding(12)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Edit Goal View
struct EditGoalView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var goal: Goal

    @State private var title: String = ""
    @State private var goalDescription: String = ""
    @State private var selectedColor: String = "#5856D6"
    @State private var selectedIcon: String = "target"
    @State private var startDate: Date = Date()
    @State private var hasTargetDate: Bool = false
    @State private var targetDate: Date = Date()
    @State private var milestones: Int = 0

    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedImageData: Data?

    private let colorOptions = [
        "#F5F0B0", "#F5D5B0", "#F0B8C0", "#F5C0D0",
        "#D4B8E0", "#B8B5E0", "#B3D4F5", "#B8E0F0",
        "#B0E8E0", "#B8E0C8", "#D0C8A8", "#B0B8C0"
    ]

    private let iconOptions = [
        "target", "star.fill", "heart.fill", "bolt.fill",
        "flame.fill", "leaf.fill", "book.fill", "briefcase.fill",
        "figure.run", "brain.head.profile", "dollarsign.circle.fill", "graduationcap.fill"
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Info") {
                    TextField("Goal Title", text: $title)

                    TextField("Description", text: $goalDescription, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Appearance") {
                    // Color picker
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Color")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                            ForEach(colorOptions, id: \.self) { color in
                                Circle()
                                    .fill(Color(hex: color) ?? .blue)
                                    .frame(width: 36, height: 36)
                                    .overlay {
                                        if color == selectedColor {
                                            Image(systemName: "checkmark")
                                                .foregroundStyle(Color(red: 0.2, green: 0.2, blue: 0.25))
                                                .fontWeight(.bold)
                                        }
                                    }
                                    .onTapGesture { selectedColor = color }
                            }
                        }
                    }
                    .padding(.vertical, 4)

                    // Icon picker
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Icon")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                            ForEach(iconOptions, id: \.self) { icon in
                                Image(systemName: icon)
                                    .font(.title3)
                                    .frame(width: 36, height: 36)
                                    .background(icon == selectedIcon ? Color(hex: selectedColor)?.opacity(0.2) : Color(.systemGray6))
                                    .foregroundStyle(icon == selectedIcon ? Color(hex: selectedColor) ?? .primary : .primary)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .onTapGesture { selectedIcon = icon }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Cover Image") {
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        if let imageData = selectedImageData,
                           let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 150)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        } else {
                            Label("Select Image", systemImage: "photo")
                        }
                    }
                    .onChange(of: selectedPhotoItem) { _, newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                selectedImageData = data
                            }
                        }
                    }

                    if selectedImageData != nil {
                        Button("Remove Image", role: .destructive) {
                            selectedImageData = nil
                            selectedPhotoItem = nil
                        }
                    }
                }

                Section("Timeline") {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)

                    Toggle("Set Target Date", isOn: $hasTargetDate)

                    if hasTargetDate {
                        DatePicker("Target Date", selection: $targetDate, in: startDate..., displayedComponents: .date)
                    }
                }

                Section("Milestones") {
                    Stepper("Milestones: \(milestones)", value: $milestones, in: 0...20)
                }
            }
            .navigationTitle("Edit Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .fontWeight(.semibold)
                    .disabled(title.isEmpty)
                }
            }
            .onAppear {
                loadGoalData()
            }
        }
    }

    private func loadGoalData() {
        title = goal.title
        goalDescription = goal.goalDescription
        selectedColor = goal.colorHex
        selectedIcon = goal.icon ?? "target"
        startDate = goal.startDate
        hasTargetDate = goal.targetDate != nil
        targetDate = goal.targetDate ?? Date()
        milestones = goal.milestones
        selectedImageData = goal.imageData
    }

    private func saveChanges() {
        goal.title = title
        goal.goalDescription = goalDescription
        goal.colorHex = selectedColor
        goal.icon = selectedIcon
        goal.startDate = startDate
        goal.targetDate = hasTargetDate ? targetDate : nil
        goal.milestones = milestones
        goal.imageData = selectedImageData
        goal.updatedAt = Date()

        dismiss()
    }
}

#Preview {
    NavigationStack {
        GoalDetailView(goal: Goal(
            title: "Learn SwiftUI",
            goalDescription: "Master SwiftUI development by building real apps",
            colorHex: "#5856D6",
            status: .inProgress,
            progress: 0.35,
            milestones: 5,
            completedMilestones: 2
        ))
    }
    .modelContainer(for: [Goal.self, GoalComment.self])
}
