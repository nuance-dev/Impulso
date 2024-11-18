import SwiftUI

struct TaskCardView: View {
    let task: ImpulsoTask
    @Binding var isHovered: Bool
    var onMetricUpdate: (TaskMetrics) -> Void
    var onFocusToggle: () -> Void
    var onComplete: () -> Void
    var onMoveToBacklog: () -> Void
    var onDelete: () -> Void
    var onNotesUpdate: (String) -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var isExpanded = false
    @State private var showingNotesEditor = false
    @State private var editingNotes: String = ""
    @State private var showingDetailView = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main task row
            HStack(spacing: 12) {
                CompletionIndicator(isCompleted: task.isCompleted, onComplete: onComplete)
                    .padding(.leading, 20)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(task.taskDescription!)
                            .font(.system(size: 14))
                            .foregroundColor(task.isCompleted ? .secondary.opacity(0.7) : .primary)
                            .strikethrough(task.isCompleted)
                        
                        if task.priorityScore > 0 {
                            PriorityBadge(score: task.priorityScore)
                        }
                        
                        if task.taskNotes != nil {
                            Image(systemName: "text.alignleft")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.3)) {
                                        isExpanded.toggle()
                                    }
                                }
                        }
                    }
                }
                
                Spacer()
                
                HStack(spacing: 12) {
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
            
            // Description section
            if isExpanded, let notes = task.taskNotes {
                Text(notes)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 48)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .onTapGesture(count: 2) {
                        editingNotes = notes
                        showingNotesEditor = true
                    }
            }
        }
        .background(
            Group {
                if task.isFocused {
                    Color.yellow.opacity(0.05)
                } else if isHovered {
                    Color(NSColor.selectedContentBackgroundColor).opacity(0.05)
                } else {
                    Color.clear
                }
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(
                    task.isFocused ? 
                        Color.yellow.opacity(0.4) : 
                        Color.primary.opacity(colorScheme == .dark ? 0.15 : 0.08),
                    lineWidth: task.isFocused ? 1.5 : 1
                )
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
            Divider()
            Button(action: {
                editingNotes = task.taskNotes ?? ""
                showingNotesEditor = true
            }) {
                Label(task.taskNotes == nil ? "Add Notes" : "Edit Notes", 
                      systemImage: "text.alignleft")
            }
            Divider()
            Button(role: .destructive, action: onDelete) {
                Label("Delete Task", systemImage: "trash")
            }
        }
        .sheet(isPresented: $showingNotesEditor) {
            TaskNotesEditor(notes: $editingNotes) { updatedNotes in
                onNotesUpdate(updatedNotes)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            showingDetailView = true
        }
        .sheet(isPresented: $showingDetailView) {
            TaskDetailView(
                task: task,
                onMetricUpdate: onMetricUpdate,
                onNotesUpdate: onNotesUpdate,
                onDelete: {
                    showingDetailView = false
                    onDelete()
                }
            )
            .frame(width: 520, height: 600)
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .contentShape(Rectangle())
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isExpanded)
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

