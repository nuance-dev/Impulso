import SwiftUI

struct MetricDots: View {
    let metrics: TaskMetrics
    let onUpdate: (MetricType, TaskMetrics.MetricValue) -> Void
    @State private var selectedType: MetricType?
    @State private var hoveredType: MetricType?
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 4) {
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
    @State private var showPopover = false
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: {
            withAnimation {
                if selectedType == type {
                    selectedType = nil
                    showPopover = false
                } else {
                    selectedType = type
                    showPopover = true
                }
            }
        }) {
            Image(systemName: type.iconName)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(foregroundColor)
                .frame(width: 24, height: 24)
                .background(backgroundColor)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(strokeColor, lineWidth: 1)
                )
                .scaleEffect(hoveredType == type ? 1.05 : 1.0)
        }
        .buttonStyle(.plain)
        .popover(isPresented: $showPopover, arrowEdge: .bottom) {
            MetricPopoverContent(
                type: type,
                currentValue: metrics.value(for: type),
                onUpdate: { value in
                    onUpdate(type, value)
                    // Keep popover open after selection
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showPopover = false
                        selectedType = nil
                    }
                }
            )
        }
        .onHover { isHovered in
            withAnimation(.easeInOut(duration: 0.2)) {
                hoveredType = isHovered ? type : nil
            }
        }
    }
    
    private var foregroundColor: Color {
        if selectedType == type {
            return type.color
        }
        return hoveredType == type ? .primary : .secondary.opacity(0.8)
    }
    
    private var backgroundColor: Color {
        if selectedType == type {
            return type.color.opacity(colorScheme == .dark ? 0.2 : 0.1)
        }
        return hoveredType == type ? Color.primary.opacity(0.05) : Color.clear
    }
    
    private var strokeColor: Color {
        if selectedType == type {
            return type.color.opacity(0.3)
        }
        return hoveredType == type ? Color.primary.opacity(0.1) : Color.clear
    }
}

struct MetricPopoverContent: View {
    let type: MetricType
    let currentValue: TaskMetrics.MetricValue
    let onUpdate: (TaskMetrics.MetricValue) -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Image(systemName: type.iconName)
                    .foregroundColor(type.color)
                Text(type.rawValue.capitalized)
                    .font(.system(size: 12, weight: .semibold))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.primary.opacity(0.05))
            
            ForEach(TaskMetrics.MetricValue.allCases, id: \.self) { value in
                MetricOptionRow(
                    value: value,
                    isSelected: currentValue == value,
                    type: type,
                    action: { onUpdate(value) }
                )
            }
        }
        .frame(width: 160)
        .background(colorScheme == .dark ? Color.black : Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: 5)
    }
}

struct MetricOptionRow: View {
    let value: TaskMetrics.MetricValue
    let isSelected: Bool
    let type: MetricType
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
                        .foregroundColor(type.color)
                }
            }
            .foregroundColor(isSelected ? .primary : .secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(
            Color.primary.opacity(isSelected ? 0.05 : 0)
        )
    }
}
