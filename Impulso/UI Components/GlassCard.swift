import SwiftUI
    
struct GlassCard: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    
    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    if colorScheme == .dark {
                        Color.black.opacity(0.2)
                    } else {
                        Color.white.opacity(0.8)
                    }
                    
                    VisualEffectBlur(
                        material: .hudWindow,
                        blendingMode: .withinWindow
                    )
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            Color.primary.opacity(colorScheme == .dark ? 0.1 : 0.05),
                            lineWidth: 1
                        )
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(
                color: Color.black.opacity(0.05),
                radius: 10,
                x: 0,
                y: 5
            )
    }
}