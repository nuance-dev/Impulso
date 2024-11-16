import SwiftUI

struct MetricDots: View {
    let metrics: TaskMetrics
    let onUpdate: (MetricType, TaskMetrics.MetricValue) -> Void
    @Binding var isHovered: Bool
    
    var body: some View {
        HStack(spacing: 6) {
            ForEach(MetricType.allCases.prefix(3)) { type in
                MetricDot(
                    type: type,
                    value: metrics.value(for: type),
                    onUpdate: { value in
                        onUpdate(type, value)
                    }
                )
                .opacity(shouldShow(for: type) ? 1 : 0)
            }
        }
    }
    
    private func shouldShow(for type: MetricType) -> Bool {
        let value = metrics.value(for: type)
        return isHovered || value != .unset
    }
}

struct MetricDot: View {
    let type: MetricType
    let value: TaskMetrics.MetricValue
    let onUpdate: (TaskMetrics.MetricValue) -> Void
    
    @State private var isHovering = false
    @State private var showPopover = false
    
    var body: some View {
        Button(action: {}) {
            Image(systemName: type.iconName)
                .font(.system(size: 11, weight: .light))
                .foregroundColor(value == .unset ? .secondary.opacity(0.3) : value.color.opacity(0.8))
                .frame(width: 20, height: 20)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovering = hovering
            if hovering {
                showPopover = true
            }
        }
        .popover(isPresented: $showPopover, arrowEdge: .bottom) {
            MetricPopover(
                type: type,
                currentValue: value,
                onUpdate: { newValue in
                    onUpdate(newValue)
                }
            )
            .onHover { hovering in
                if !hovering && !isHovering {
                    showPopover = false
                }
            }
        }
    }
}

struct MetricPopover: View {
    let type: MetricType
    let currentValue: TaskMetrics.MetricValue
    let onUpdate: (TaskMetrics.MetricValue) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(TaskMetrics.MetricValue.allCases, id: \.self) { value in
                MetricOptionButton(
                    value: value,
                    isSelected: value == currentValue,
                    color: value.color
                ) {
                    onUpdate(value)
                }
            }
        }
        .frame(width: 120)
        .padding(.vertical, 4)
        .background(Color(NSColor.windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

struct MetricOptionButton: View {
    let value: TaskMetrics.MetricValue
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(value.description)
                    .font(.system(size: 12))
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(color)
                }
            }
            .foregroundColor(isSelected ? .primary : .secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(isSelected ? color.opacity(0.1) : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

