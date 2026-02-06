//
//  AddGoalView.swift
//  TimeTrace
//
//  Created by Claude Code on 2/6/26.
//

import SwiftUI
import SwiftData
import PhotosUI

struct AddGoalView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var title = ""
    @State private var goalDescription = ""
    @State private var selectedColor = "#5856D6"
    @State private var selectedIcon = "target"
    @State private var startDate = Date()
    @State private var hasTargetDate = false
    @State private var targetDate = Date().addingTimeInterval(30 * 24 * 60 * 60) // 30 days from now
    @State private var milestones = 0

    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedImageData: Data?

    @State private var currentStep = 0

    private let colorOptions = [
        "#5856D6", "#AF52DE", "#007AFF", "#34C759",
        "#FF9500", "#FF2D55", "#00C7BE", "#FF6482",
        "#5AC8FA", "#FFCC00", "#8E8E93", "#30B0C7"
    ]

    private let iconOptions = [
        "target", "star.fill", "heart.fill", "bolt.fill",
        "flame.fill", "leaf.fill", "book.fill", "briefcase.fill",
        "figure.run", "brain.head.profile", "dollarsign.circle.fill", "graduationcap.fill",
        "music.note", "paintpalette.fill", "camera.fill", "airplane"
    ]

    var body: some View {
        NavigationStack {
            Form {
                // Basic Info Section
                Section {
                    TextField("Goal Title", text: $title)
                        .font(.headline)

                    TextField("Description (optional)", text: $goalDescription, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("What's your goal?")
                } footer: {
                    Text("Give your goal a clear, actionable title.")
                }

                // Appearance Section
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
                                    .frame(width: 40, height: 40)
                                    .overlay {
                                        if color == selectedColor {
                                            Image(systemName: "checkmark")
                                                .foregroundStyle(.white)
                                                .fontWeight(.bold)
                                        }
                                    }
                                    .shadow(color: color == selectedColor ? (Color(hex: color) ?? .blue).opacity(0.5) : .clear, radius: 4)
                                    .onTapGesture {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            selectedColor = color
                                        }
                                    }
                            }
                        }
                    }
                    .padding(.vertical, 4)

                    // Icon picker
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Icon")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 12) {
                            ForEach(iconOptions, id: \.self) { icon in
                                Image(systemName: icon)
                                    .font(.title3)
                                    .frame(width: 36, height: 36)
                                    .background(
                                        icon == selectedIcon
                                        ? (Color(hex: selectedColor) ?? .blue).opacity(0.2)
                                        : Color(.systemGray6)
                                    )
                                    .foregroundStyle(
                                        icon == selectedIcon
                                        ? (Color(hex: selectedColor) ?? .blue)
                                        : .primary
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .onTapGesture {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            selectedIcon = icon
                                        }
                                    }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }

                // Cover Image Section
                Section {
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        if let imageData = selectedImageData,
                           let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 150)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        } else {
                            HStack {
                                Image(systemName: "photo.on.rectangle.angled")
                                    .font(.title2)
                                    .foregroundStyle(Color(hex: selectedColor) ?? .blue)
                                Text("Add Cover Image")
                                    .foregroundStyle(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 8)
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
                            withAnimation {
                                selectedImageData = nil
                                selectedPhotoItem = nil
                            }
                        }
                    }
                } header: {
                    Text("Cover Image (Optional)")
                }

                // Timeline Section
                Section {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)

                    Toggle("Set Target Date", isOn: $hasTargetDate.animation())

                    if hasTargetDate {
                        DatePicker("Target Date", selection: $targetDate, in: startDate..., displayedComponents: .date)
                    }
                } header: {
                    Text("Timeline")
                } footer: {
                    Text("Setting a target date helps you stay accountable.")
                }

                // Milestones Section
                Section {
                    Stepper("Number of milestones: \(milestones)", value: $milestones, in: 0...20)
                } header: {
                    Text("Milestones")
                } footer: {
                    Text("Break your goal into smaller milestones to track progress more effectively.")
                }

                // Preview Section
                Section("Preview") {
                    GoalPreviewTile(
                        title: title.isEmpty ? "Your Goal" : title,
                        description: goalDescription,
                        colorHex: selectedColor,
                        icon: selectedIcon,
                        hasTargetDate: hasTargetDate,
                        targetDate: targetDate
                    )
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("New Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createGoal()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(Color(hex: selectedColor) ?? Theme.primary)
                    .disabled(title.isEmpty)
                }
            }
        }
    }

    private func createGoal() {
        let goal = Goal(
            title: title,
            goalDescription: goalDescription,
            colorHex: selectedColor,
            status: .notStarted,
            startDate: startDate,
            targetDate: hasTargetDate ? targetDate : nil,
            progress: 0.0,
            milestones: milestones,
            completedMilestones: 0,
            imageData: selectedImageData,
            icon: selectedIcon
        )

        modelContext.insert(goal)
        dismiss()
    }
}

// MARK: - Goal Preview Tile
struct GoalPreviewTile: View {
    let title: String
    let description: String
    let colorHex: String
    let icon: String
    let hasTargetDate: Bool
    let targetDate: Date

    private var tileColor: Color {
        Color(hex: colorHex) ?? Theme.primary
    }

    private var daysRemaining: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: targetDate)
        return components.day ?? 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(.white.opacity(0.9))

                Spacer()

                Image(systemName: "circle")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
            }

            Spacer()

            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .lineLimit(2)

            if !description.isEmpty {
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
                    .lineLimit(2)
            }

            HStack(spacing: 4) {
                Image(systemName: "calendar")
                    .font(.caption2)
                Text(hasTargetDate ? "\(daysRemaining) days remaining" : "No deadline set")
                    .font(.caption2)
            }
            .foregroundStyle(.white.opacity(0.7))

            // Progress bar placeholder
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Progress")
                        .font(.caption2)
                    Spacer()
                    Text("0%")
                        .font(.caption2)
                        .fontWeight(.medium)
                }
                .foregroundStyle(.white.opacity(0.8))

                RoundedRectangle(cornerRadius: 4)
                    .fill(.white.opacity(0.3))
                    .frame(height: 6)
            }
        }
        .padding(16)
        .frame(height: 180)
        .background(
            LinearGradient(
                colors: [tileColor, tileColor.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: AppConstants.UI.cornerRadius))
        .shadow(color: tileColor.opacity(0.3), radius: 8, y: 4)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

#Preview {
    AddGoalView()
        .modelContainer(for: [Goal.self, GoalComment.self])
}
