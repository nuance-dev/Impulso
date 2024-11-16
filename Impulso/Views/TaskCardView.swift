import SwiftUI

struct TaskCardView: View {
    let task: ImpulsoTask
    @Binding var isHovered: Bool
    var onMetricUpdate: (TaskMetrics) -> Void
    var onFocusToggle: () -> Void
    var onComplete: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 16) {
            // Completion Indicator
            CompletionIndicator(isCompleted: task.isCompleted, onComplete: onComplete)
            
            // Task Details
            VStack(alignment: .leading, spacing: 4) {
                // Task Description
                Text(task.taskDescription)
                    .font(.headline)
                    .foregroundColor(task.isCompleted ? .secondary : .primary)
                    .strikethrough(task.isCompleted)
                
                // Priority Score
                Text("Priority: \(Int(task.priorityScore))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .opacity(isHovered ? 1 : 0.7)
            }
            
            Spacer()
            
            // Right Side Controls
            HStack(spacing: 12) {
                if let metrics = task.metrics {
                    MetricDots(metrics: metrics) { type, value in
                        var updatedMetrics = metrics
                        updatedMetrics.update(type: type, value: value)
                        onMetricUpdate(updatedMetrics)
                    }
                    .opacity(isHovered ? 1 : 0.5)
                }
                
                // Focus Indicator
                FocusIndicator(isFocused: task.isFocused, onToggle: onFocusToggle)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.primary.opacity(0.06))
                )
                .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
    
    private var backgroundColor: Color {
        if colorScheme == .dark {
            return Color.black.opacity(0.2)
        } else {
            return Color.white.opacity(0.8)
        }
    }
}

struct CompletionIndicator: View {
    let isCompleted: Bool
    var onComplete: () -> Void
    
    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(isCompleted ? Color.green.opacity(0.8) : Color.gray.opacity(0.15), lineWidth: 1.5)
                .frame(width: 16, height: 16)
            
            if isCompleted {
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.green)
            }
        }
        .contentShape(Circle())
        .onTapGesture(perform: onComplete)
    }
}

struct FocusIndicator: View {
    let isFocused: Bool
    var onToggle: () -> Void
    
    var body: some View {
        Image(systemName: isFocused ? "star.fill" : "star")
            .font(.system(size: 12))
            .foregroundColor(isFocused ? .yellow : .gray.opacity(0.3))
            .opacity(isFocused ? 1 : 0.5)
            .onTapGesture(perform: onToggle)
    }
}