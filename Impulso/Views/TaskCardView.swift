import SwiftUI

struct TaskCardView: View {
    let task: ImpulsoTask
    @Binding var isHovered: Bool
    var onMetricUpdate: (TaskMetrics) -> Void
    var onFocusToggle: () -> Void
    var onComplete: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            // Completion Indicator
            CompletionIndicator(isCompleted: task.isCompleted, onComplete: onComplete)
                .padding(.leading, 2)
            
            // Task Details
            VStack(alignment: .leading, spacing: 3) {
                Text(task.taskDescription)
                    .font(.system(size: 13))
                    .foregroundColor(task.isCompleted ? .secondary.opacity(0.7) : .primary)
                    .strikethrough(task.isCompleted)
                
                Text("Priority: \(Int(task.priorityScore))")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary.opacity(0.7))
                    .opacity(isHovered ? 1 : 0.7)
            }
            
            Spacer()
            
            // Right Side Controls
            HStack(spacing: 8) {
                if let metrics = task.metrics {
                    MetricDots(metrics: metrics) { type, value in
                        var updatedMetrics = metrics
                        updatedMetrics.update(type: type, value: value)
                        onMetricUpdate(updatedMetrics)
                    }
                    .opacity(isHovered ? 1 : 0.5)
                }
                
                FocusIndicator(isFocused: task.isFocused, onToggle: onFocusToggle)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.primary.opacity(0.04))
                )
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
    
    private var backgroundColor: Color {
        if colorScheme == .dark {
            return Color.black.opacity(0.15)
        } else {
            return Color.white.opacity(0.7)
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