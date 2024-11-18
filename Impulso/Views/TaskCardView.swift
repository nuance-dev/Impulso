import SwiftUI

struct TaskCardView: View {
    let task: ImpulsoTask
    @Binding var isHovered: Bool
    var onMetricUpdate: (TaskMetrics) -> Void
    var onFocusToggle: () -> Void
    var onComplete: () -> Void
    var onMoveToBacklog: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            // Completion Indicator
            CompletionIndicator(isCompleted: task.isCompleted, onComplete: onComplete)
                .padding(.leading, 20)
            
            // Task Details
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(task.taskDescription!)
                        .font(.system(size: 14))
                        .foregroundColor(task.isCompleted ? .secondary.opacity(0.7) : .primary)
                        .strikethrough(task.isCompleted)
                    
                    if task.priorityScore > 0 {
                        PriorityBadge(score: task.priorityScore)
                    }
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
                if task.isFocused {
                    Color.yellow.opacity(0.05)
                } else if isHovered {
                    Color(NSColor.selectedContentBackgroundColor).opacity(0.1)
                } else {
                    Color.clear
                }
            }
        )
        .overlay(
            Group {
                if task.isFocused {
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                }
            }
        )
        .contextMenu {
            if !task.isBacklogged {
                Button(action: onMoveToBacklog) {
                    Label("Move to Backlog", systemImage: "archivebox")
                }
            }
            Button(action: onFocusToggle) {
                Label(task.isFocused ? "Remove Focus" : "Focus Task", 
                      systemImage: task.isFocused ? "star.slash" : "star")
            }
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
