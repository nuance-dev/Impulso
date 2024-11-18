import SwiftUI

struct MetricDots: View {
    let metrics: TaskMetrics
    let onUpdate: (MetricType, TaskMetrics.MetricValue) -> Void
    @Binding var isHovered: Bool
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(MetricType.allCases) { type in
                MetricDot(
                    type: type,
                    value: metrics.value(for: type),
                    onUpdate: { value in
                        onUpdate(type, value)
                    }
                )
                .opacity(shouldShow(for: type) ? 1 : 0)
                .animation(.easeOut(duration: 0.1), value: isHovered)
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
    @State private var currentSelection: TaskMetrics.MetricValue
    @State private var hideTimer: Timer?
    @Environment(\.colorScheme) private var colorScheme
    
    init(type: MetricType, value: TaskMetrics.MetricValue, onUpdate: @escaping (TaskMetrics.MetricValue) -> Void) {
        self.type = type
        self.value = value
        self.onUpdate = onUpdate
        _currentSelection = State(initialValue: value)
    }
    
    var body: some View {
        Button(action: {}) {
            Image(systemName: type.iconName)
                .font(.system(size: 12, weight: .light))
                .foregroundColor(dotColor)
                .frame(width: 24, height: 24)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(isHovering ? Color.primary.opacity(0.05) : .clear)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .onHover { hovering in
            if hovering {
                hideTimer?.invalidate()
                hideTimer = nil
                showPopover = true
                isHovering = true
            } else {
                isHovering = false
                hideTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
                    if !isHovering {
                        showPopover = false
                    }
                }
            }
        }
        .popover(isPresented: $showPopover, arrowEdge: .bottom) {
            MetricPopover(
                type: type,
                currentValue: currentSelection,
                onUpdate: { newValue in
                    currentSelection = newValue
                    onUpdate(newValue)
                }
            )
            .onHover { hovering in
                isHovering = hovering
                if hovering {
                    hideTimer?.invalidate()
                    hideTimer = nil
                } else {
                    hideTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
                        if !isHovering {
                            showPopover = false
                        }
                    }
                }
            }
        }
        .onChange(of: value) { _, newValue in
            currentSelection = newValue
        }
    }
    
    private var dotColor: Color {
        switch value {
        case .unset: return .secondary.opacity(0.4)
        case .low: return .yellow.opacity(0.9)
        case .medium: return .orange.opacity(0.9)
        case .high: return .red.opacity(0.9)
        }
    }
}

struct MetricPopover: View {
    let type: MetricType
    let currentValue: TaskMetrics.MetricValue
    let onUpdate: (TaskMetrics.MetricValue) -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            Text(type.title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.primary)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .frame(maxWidth: .infinity)
            
            Divider()
            
            HStack(spacing: 0) {
                ForEach(TaskMetrics.MetricValue.allCases, id: \.self) { value in
                    Button(action: { onUpdate(value) }) {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(value.color)
                                .frame(width: 8, height: 8)
                            Text(value.description)
                                .font(.system(size: 12))
                                .foregroundColor(value == currentValue ? .primary : .secondary)
                                .fixedSize(horizontal: true, vertical: false)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 28)
                        .padding(.horizontal, 12)
                        .background(value == currentValue ? Color.primary.opacity(0.06) : .clear)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 4)
        }
        .frame(width: 300)
        .background(
            ZStack {
                if colorScheme == .dark {
                    Color.black.opacity(0.85)
                } else {
                    Color.white.opacity(0.85)
                }
                VisualEffectBlur(material: .popover, blendingMode: .withinWindow)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
        )
        .fixedSize()
    }
}

