import SwiftUI

struct TaskCardView: View {
    let task: ImpulsoTask
    @Binding var isHovered: Bool
    let onMetricUpdate: (TaskMetrics) -> Void
    let onFocusToggle: () -> Void
    let onComplete: () -> Void
    let onMoveToBacklog: () -> Void
    let onDelete: () -> Void
    let onNotesUpdate: (String?) -> Void
    let onExpandedHeightChange: (CGFloat) -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var isExpanded = false
    @State private var showingNotesEditor = false
    @State private var editingNotes: String = ""
    @State private var showingDetailView = false
    @State private var expandedHeight: CGFloat = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main task row
            HStack(spacing: 12) {
                CompletionIndicator(isCompleted: task.isCompleted, onComplete: onComplete)
                    .padding(.leading, 20)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(task.taskDescription ?? "Untitled Task")
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
                    .background(Color.clear)
                    .contentShape(Rectangle())
                    .onTapGesture(count: 2) {
                        editingNotes = notes
                        showingNotesEditor = true
                    }
            }
        }
        .background(
            GeometryReader { geometry in
                Color.clear.preference(
                    key: ViewHeightKey.self,
                    value: geometry.size.height
                )
            }
        )
        .onPreferenceChange(ViewHeightKey.self) { height in
            onExpandedHeightChange(height)
        }
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
                    Label(
                        task.isBacklogged ? "Restore from Backlog" : "Move to Backlog",
                        systemImage: task.isBacklogged ? "tray.and.arrow.up" : "archivebox"
                    )
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
            ZStack {
                Color.black.opacity(0.001) // Nearly transparent background
                    .ignoresSafeArea()
                    .onTapGesture {
                        showingDetailView = false
                    }
                
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
            .interactiveDismissDisabled(true) // Prevent default sheet dismissal
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

private struct ViewHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

