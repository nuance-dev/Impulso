import SwiftUI

struct MetricDots: View {
    let metrics: TaskMetrics
    let onUpdate: (MetricType, TaskMetrics.MetricValue) -> Void
    @Binding var isHovered: Bool
    
    var body: some View {
        HStack(spacing: 6) {
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
    @State private var hoverTimer: Timer?
    
    var body: some View {
        Button(action: {}) {
            Image(systemName: type.iconName)
                .font(.system(size: 11, weight: .light))
                .foregroundColor(value == .unset ? .secondary.opacity(0.3) : type.color.opacity(0.8))
                .frame(width: 20, height: 20)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovering = hovering
            hoverTimer?.invalidate()
            
            if hovering {
                showPopover = true
            } else {
                // Shorter delay for better responsiveness
                hoverTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { _ in
                    if !isHovering {
                        showPopover = false
                    }
                }
            }
        }
        .popover(isPresented: $showPopover, arrowEdge: .bottom) {
            MetricPopover(
                type: type,
                currentValue: value,
                onUpdate: onUpdate
            )
            .onHover { hovering in
                isHovering = hovering
                hoverTimer?.invalidate()
                if !hovering {
                    hoverTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { _ in
                        if !isHovering {
                            showPopover = false
                        }
                    }
                }
            }
        }
        .onChange(of: showPopover) { _, isShowing in
            if !isShowing {
                hoverTimer?.invalidate()
            }
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
            // Header
            Text(type.title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(colorScheme == .dark ? .white : .black)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .frame(maxWidth: .infinity)
                .background(colorScheme == .dark ? Color.black.opacity(0.4) : Color.white.opacity(0.4))
            
            // Options
            HStack(spacing: 0) {
                ForEach(TaskMetrics.MetricValue.allCases, id: \.self) { value in
                    Button(action: { onUpdate(value) }) {
                        Text(value.description)
                            .font(.system(size: 12))
                            .foregroundColor(
                                isSelected(value) 
                                    ? type.color 
                                    : (colorScheme == .dark ? .white.opacity(0.8) : .black.opacity(0.8))
                            )
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(isSelected(value) ? type.color.opacity(0.1) : Color.clear)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .frame(width: 70)
                }
            }
            .padding(.vertical, 4)
        }
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(colorScheme == .dark ? Color.black.opacity(0.95) : Color.white.opacity(0.95))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                )
        )
        .fixedSize()
    }
    
    private func isSelected(_ value: TaskMetrics.MetricValue) -> Bool {
        value == currentValue
    }
}

