import SwiftUI

struct PriorityBadge: View {
    let score: Double
    @Environment(\.colorScheme) private var colorScheme
    
    private var priorityColor: Color {
        switch score {
        case 0: return .secondary.opacity(0.5)
        case 1...40: return .blue
        case 41...70: return .orange
        default: return .red
        }
    }
    
    private var backgroundColor: Color {
        colorScheme == .dark 
            ? priorityColor.opacity(0.15) 
            : priorityColor.opacity(0.1)
    }
    
    var body: some View {
        Text("\(Int(score))")
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(score == 0 ? .secondary.opacity(0.5) : priorityColor)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(score == 0 ? Color.secondary.opacity(0.1) : backgroundColor)
            .cornerRadius(4)
    }
} 