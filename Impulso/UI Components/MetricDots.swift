import SwiftUI

struct MetricDots: View {
    let metrics: TaskMetrics
    let onUpdate: (MetricType, TaskMetrics.MetricValue) -> Void
    @State private var selectedType: MetricType?
    @State private var hoveredType: MetricType?
    
    var body: some View {
        HStack(spacing: 6) {
            ForEach(MetricType.allCases.prefix(3)) { type in
                MetricDotButton(
                    type: type,
                    metrics: metrics,
                    selectedType: $selectedType,
                    hoveredType: $hoveredType,
                    onUpdate: onUpdate
                )
            }
        }
        .animation(.easeInOut(duration: 0.2), value: selectedType)
    }
}

struct MetricDotButton: View {
    let type: MetricType
    let metrics: TaskMetrics
    @Binding var selectedType: MetricType?
    @Binding var hoveredType: MetricType?
    let onUpdate: (MetricType, TaskMetrics.MetricValue) -> Void
    
    var body: some View {
        MetricButton(
            value: metrics.value(for: type),
            type: type,
            isSelected: selectedType == type,
            action: {
                toggleMetric(type)
            }
        )
        .popover(isPresented: Binding(
            get: { hoveredType == type },
            set: { if !$0 { hoveredType = nil } }
        )) {
            MetricPopoverContent(
                type: type,
                currentValue: metrics.value(for: type),
                onUpdate: onUpdate
            )
        }
        .onHover { isHovered in
            hoveredType = isHovered ? type : nil
        }
    }
    
    private func toggleMetric(_ type: MetricType) {
        if selectedType == type {
            selectedType = nil
        } else {
            selectedType = type
        }
    }
}

struct MetricPopoverContent: View {
    let type: MetricType
    let currentValue: TaskMetrics.MetricValue
    let onUpdate: (MetricType, TaskMetrics.MetricValue) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(type.rawValue.capitalized)
                .font(.headline)
            MetricSelectorView(
                metric: currentValue,
                onChange: { newValue in
                    onUpdate(type, newValue)
                }
            )
        }
        .padding(8)
    }
}

struct MetricButton: View {
    let value: TaskMetrics.MetricValue
    let type: MetricType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Circle()
            .fill(isSelected ? type.color : Color.clear)
            .frame(width: 8, height: 8)
            .overlay(
                Circle()
                    .stroke(type.color, lineWidth: 1)
            )
            .onTapGesture(perform: action)
    }
}
