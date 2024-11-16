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
                .padding(.leading, 20)
            
            // Task Details
            VStack(alignment: .leading, spacing: 4) {
                Text(task.taskDescription!)
                    .font(.system(size: 14))
                    .foregroundColor(task.isCompleted ? .secondary.opacity(0.7) : .primary)
                    .strikethrough(task.isCompleted)
                
                if isHovered {
                    Text("Priority: \(Int(task.priorityScore))")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary.opacity(0.7))
                }
            }
            
            Spacer()
            
            // Right Side Controls
            HStack(spacing: 8) {
                if let metrics = task.metrics {
                    MetricDots(metrics: metrics, onUpdate: { type, value in
                        var updatedMetrics = metrics
                        updatedMetrics.update(type: type, value: value)
                        onMetricUpdate(updatedMetrics)
                    }, isHovered: $isHovered)
                }
                
                FocusIndicator(isFocused: task.isFocused, onToggle: onFocusToggle)
                    .padding(.trailing, 20)
            }
        }
        .frame(height: 44)
        .background(
            Group {
                if isHovered {
                    Color(NSColor.selectedContentBackgroundColor).opacity(0.1)
                } else {
                    Color.clear
                }
            }
        )
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
