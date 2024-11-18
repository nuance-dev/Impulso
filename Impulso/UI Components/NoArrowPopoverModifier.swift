import SwiftUI

struct NoArrowPopoverModifier: ViewModifier {
    let isPresented: Binding<Bool>
    let content: () -> any View
    
    func body(content: Content) -> some View {
        content
            .background(
                PopoverAnchorView(
                    isPresented: isPresented,
                    popoverContent: self.content
                )
            )
    }
}

private struct PopoverAnchorView: NSViewRepresentable {
    let isPresented: Binding<Bool>
    let popoverContent: () -> any View
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        if isPresented.wrappedValue {
            if context.coordinator.popover == nil {
                let popover = NSPopover()
                popover.behavior = .transient
                popover.animates = true
                popover.contentSize = NSSize(width: 200, height: 100)
                popover.contentViewController = NSHostingController(
                    rootView: AnyView(popoverContent())
                )
                
                if let popoverWindow = popover.contentViewController?.view.window {
                    popoverWindow.backgroundColor = .clear
                }
                
                context.coordinator.popover = popover
                
                popover.show(
                    relativeTo: NSRect(x: 0, y: -4, width: nsView.bounds.width, height: 4),
                    of: nsView,
                    preferredEdge: .maxY
                )
            }
        } else {
            context.coordinator.popover?.close()
            context.coordinator.popover = nil
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator {
        var popover: NSPopover?
    }
}

extension View {
    func noArrowPopover<Content: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        self.modifier(NoArrowPopoverModifier(
            isPresented: isPresented,
            content: content
        ))
    }
} 