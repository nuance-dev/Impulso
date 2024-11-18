import SwiftUI

struct TaskDetailView: View {
    let task: ImpulsoTask
    var onMetricUpdate: (TaskMetrics) -> Void
    var onNotesUpdate: (String) -> Void
    var onDelete: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var editingDescription: String
    @State private var editingNotes: String
    @State private var showingDeleteConfirm = false
    @FocusState private var isEditingNotes: Bool
    
    init(task: ImpulsoTask, 
         onMetricUpdate: @escaping (TaskMetrics) -> Void,
         onNotesUpdate: @escaping (String) -> Void,
         onDelete: @escaping () -> Void) {
        self.task = task
        self.onMetricUpdate = onMetricUpdate
        self.onNotesUpdate = onNotesUpdate
        self.onDelete = onDelete
        self._editingDescription = State(initialValue: task.taskDescription ?? "")
        self._editingNotes = State(initialValue: task.taskNotes ?? "")
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Minimal header with subtle actions
            HStack(spacing: 16) {
                TextField("Task description", text: $editingDescription)
                    .font(.system(size: 16))
                    .textFieldStyle(.plain)
                    .onAppear {
                        // Delay to prevent automatic selection
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            NSApp.keyWindow?.makeFirstResponder(nil)
                        }
                    }
                
                Spacer()
                
                HStack(spacing: 20) {
                    Button(action: { showingDeleteConfirm = true }) {
                        Image(systemName: "trash")
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary.opacity(0.8))
                    
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary.opacity(0.8))
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .background(Color(NSColor.windowBackgroundColor).opacity(0.5))
            
            Divider()
                .opacity(0.15)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    // Metrics section with refined cards
                    VStack(alignment: .leading, spacing: 16) {
                        Text("METRICS")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary.opacity(0.8))
                            .padding(.horizontal, 2)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            ForEach(MetricType.allCases) { type in
                                MetricCard(
                                    type: type,
                                    value: task.metrics?.value(for: type) ?? .unset,
                                    onChange: { value in
                                        var updatedMetrics = task.metrics ?? TaskMetrics()
                                        updatedMetrics.update(type: type, value: value)
                                        onMetricUpdate(updatedMetrics)
                                    }
                                )
                            }
                        }
                    }
                    
                    // Notes section with minimal styling
                    VStack(alignment: .leading, spacing: 12) {
                        Text("NOTES")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary.opacity(0.8))
                            .padding(.horizontal, 2)
                        
                        TextEditor(text: $editingNotes)
                            .font(.system(size: 13))
                            .focused($isEditingNotes)
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 120)
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color(NSColor.textBackgroundColor).opacity(0.3))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.primary.opacity(colorScheme == .dark ? 0.1 : 0.05), 
                                           lineWidth: 0.5)
                            )
                            .onChange(of: editingNotes) { _, newValue in
                                onNotesUpdate(newValue)
                            }
                    }
                }
                .padding(24)
            }
        }
        .background(VisualEffectBlur(material: .popover, blendingMode: .withinWindow))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.primary.opacity(colorScheme == .dark ? 0.08 : 0.04), lineWidth: 1)
        )
        .alert("Delete Task", isPresented: $showingDeleteConfirm) {
            Button("Delete", role: .destructive, action: onDelete)
            Button("Cancel", role: .cancel) { }
        }
    }
}

struct MetricCard: View {
    let type: MetricType
    let value: TaskMetrics.MetricValue
    let onChange: (TaskMetrics.MetricValue) -> Void
    @Environment(\.colorScheme) private var colorScheme
    @State private var showingPopover = false
    
    var body: some View {
        Button {
            showingPopover.toggle()
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: type.iconName)
                        .font(.system(size: 12))
                        .foregroundColor(type.color.opacity(0.8))
                    Text(type.shortTitle)
                        .font(.system(size: 12))
                        .foregroundColor(.primary.opacity(0.8))
                }
                
                Text(value.description)
                    .font(.system(size: 13))
                    .foregroundColor(value == .unset ? .secondary.opacity(0.7) : .primary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(NSColor.controlBackgroundColor).opacity(0.5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.primary.opacity(colorScheme == .dark ? 0.08 : 0.04), 
                                  lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .popover(isPresented: $showingPopover, arrowEdge: .bottom) {
            VStack(spacing: 2) {
                ForEach(TaskMetrics.MetricValue.allCases, id: \.self) { metricValue in
                    Button {
                        onChange(metricValue)
                        showingPopover = false
                    } label: {
                        HStack {
                            Text(metricValue.description)
                                .font(.system(size: 12))
                            Spacer()
                            if value == metricValue {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10))
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .frame(width: 120)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 4)
            .background(VisualEffectBlur(material: .popover, blendingMode: .withinWindow))
        }
    }
}
