import SwiftUI
    
struct GlassCard: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    
    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    if colorScheme == .dark {
                        Color.black.opacity(0.15)
                    } else {
                        Color.white.opacity(0.7)
                    }
                    
                    VisualEffectBlur(
                        material: .hudWindow,
                        blendingMode: .withinWindow
                    )
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            Color.primary.opacity(colorScheme == .dark ? 0.08 : 0.04),
                            lineWidth: 0.5
                        )
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .shadow(
                color: Color.black.opacity(0.03),
                radius: 4,
                x: 0,
                y: 2
            )
    }
}