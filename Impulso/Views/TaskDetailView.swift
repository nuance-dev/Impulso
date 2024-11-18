
import SwiftUI

struct TaskDetailView: View {
    let task: ImpulsoTask
    let onMetricUpdate: (TaskMetrics) -> Void
    let onNotesUpdate: (String) -> Void
    let onDelete: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var editedDescription: String
    @State private var editedNotes: String
    @State private var showingDeleteAlert = false
    
    init(task: ImpulsoTask, onMetricUpdate: @escaping (TaskMetrics) -> Void, onNotesUpdate: @escaping (String) -> Void, onDelete: @escaping () -> Void) {
        self.task = task
        self.onMetricUpdate = onMetricUpdate
        self.onNotesUpdate = onNotesUpdate
        self.onDelete = onDelete
        _editedDescription = State(initialValue: task.taskDescription ?? "")
        _editedNotes = State(initialValue: task.taskNotes ?? "")
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(role: .destructive, action: { showingDeleteAlert = true }) {
                    Image(systemName: "trash")
                        .font(.system(size: 14))
                }
            }
            .padding()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Title section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Title")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        
                        TextField("Task description", text: $editedDescription)
                            .font(.system(size: 16))
                            .textFieldStyle(.plain)
                            .padding(12)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(6)
                            .onChange(of: editedDescription) { _, newValue in
                                onNotesUpdate(newValue)
                            }
                    }
                    
                    // Metrics section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Metrics")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        
                        ForEach(MetricType.allCases) { type in
                            MetricRow(
                                type: type,
                                value: task.metrics?.value(for: type) ?? .unset,
                                onChange: { newValue in
                                    var updatedMetrics = task.metrics ?? TaskMetrics()
                                    updatedMetrics.update(type: type, value: newValue)
                                    onMetricUpdate(updatedMetrics)
                                }
                            )
                        }
                    }
                    
                    // Notes section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        
                        TextEditor(text: $editedNotes)
                            .font(.system(size: 14))
                            .frame(minHeight: 100)
                            .padding(8)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(6)
                            .onChange(of: editedNotes) { _, newValue in
                                onNotesUpdate(newValue)
                            }
                    }
                }
                .padding(24)
            }
        }
        .background(VisualEffectBlur(material: .popover, blendingMode: .behindWindow))
        .alert("Delete Task", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("Are you sure you want to delete this task? This action cannot be undone.")
        }
    }
}

struct MetricRow: View {
    let type: MetricType
    let value: TaskMetrics.MetricValue
    let onChange: (TaskMetrics.MetricValue) -> Void
    
    var body: some View {
        HStack {
            Label(type.title, systemImage: type.iconName)
                .font(.system(size: 14))
            
            Spacer()
            
            Menu {
                ForEach(TaskMetrics.MetricValue.allCases, id: \.self) { metricValue in
                    Button(action: { onChange(metricValue) }) {
                        HStack {
                            Text(metricValue.description)
                            if value == metricValue {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                Text(value.description)
                    .font(.system(size: 14))
                    .foregroundColor(.primary)
            }
        }
        .padding(8)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(6)
    }
}
