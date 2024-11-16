import SwiftUI

struct MetricDots: View {
    let metrics: TaskMetrics
    let onUpdate: (MetricType, TaskMetrics.MetricValue) -> Void
    @State private var selectedType: MetricType?
    @State private var hoveredType: MetricType?
    
    var body: some View {
        HStack(spacing: 6) {
            ForEach(MetricType.allCases.prefix(3)) { type in
                MetricButton(
                    value: metrics.value(for: type),
                    isSelected: selectedType == type,
                    action: {
                        toggleMetric(type)
                    }
                )
                .popover(isPresented: Binding(
                    get: { hoveredType == type },
                    set: { if !$0 { hoveredType = nil } }
                )) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(type.rawValue.capitalized)
                            .font(.headline)
                        MetricSelectorView(
                            currentValue: metrics.value(for: type),
                            onChange: { newValue in
                                onUpdate(type, newValue)
                            }
                        )
                    }
                    .padding(8)
                }
                .onHover { isHovered in
                    hoveredType = isHovered ? type : nil
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: selectedType)
    }
    
    private func toggleMetric(_ type: MetricType) {
        if selectedType == type {
            selectedType = nil
        } else {
            selectedType = type
        }
    }
}

struct MetricButton: View {
    let value: TaskMetrics.MetricValue
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Circle()
            .fill(isSelected ? value.color : Color.clear)
            .frame(width: 8, height: 8)
            .overlay(
                Circle()
                    .stroke(value.color, lineWidth: 1)
            )
            .onTapGesture(perform: action)
    }
}

struct MetricSelectorView: View {
    let currentValue: TaskMetrics.MetricValue
    let onChange: (TaskMetrics.MetricValue) -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            ForEach(TaskMetrics.MetricValue.allCases, id: \.self) { value in
                Button(action: { onChange(value) }) {
                    HStack {
                        Text(value.description)
                        Spacer()
                        if currentValue == value {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .frame(width: 120)
    }
}