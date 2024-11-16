import SwiftUI

struct TaskViewSelector: View {
    @Binding var selection: TaskViewState
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach([TaskViewState.active, .completed, .backlog], id: \.self) { state in
                Button(action: { selection = state }) {
                    HStack(spacing: 6) {
                        Text(state.title)
                            .font(.system(size: 13, weight: selection == state ? .medium : .regular))
                        
                        if selection == state {
                            Text("12") // Replace with actual count
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(selection == state ? backgroundColor : Color.clear)
                    .foregroundColor(selection == state ? .primary : .secondary)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(colorScheme == .dark ? Color.black.opacity(0.2) : Color.white.opacity(0.5))
        )
    }
    
    private var backgroundColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.06)
    }
}

extension TaskViewState {
    var title: String {
        switch self {
        case .active: return "Active"
        case .completed: return "Completed"
        case .backlog: return "Backlog"
        }
    }
} 