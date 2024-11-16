import SwiftUI

struct CommandMenu: View {
    @Binding var isPresented: Bool
    let onSubmit: (String) -> Void
    @State private var text = ""
    @FocusState private var isFocused: Bool
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                
                TextField("Type a command or search...", text: $text)
                    .font(.system(size: 14))
                    .textFieldStyle(PlainTextFieldStyle())
                    .focused($isFocused)
                    .onSubmit {
                        if !text.isEmpty {
                            onSubmit(text)
                            text = ""
                            isPresented = false
                        }
                    }
                
                Text("⌘K")
                    .font(.system(size: 12))
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.2))
                    .cornerRadius(4)
                    .foregroundColor(.secondary)
            }
            .padding()
            
            Divider()
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Create new...")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                
                Button(action: {
                    onSubmit("New Task")
                    isPresented = false
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.blue)
                        Text("Create Task")
                        Spacer()
                        Text("⌘N")
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                .buttonStyle(CommandMenuButtonStyle())
            }
        }
        .frame(width: 480)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color.black : Color.white)
                .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
        )
        .onAppear {
            isFocused = true
        }
    }
}

struct CommandMenuButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var colorScheme
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? backgroundColor : Color.clear)
            .contentShape(Rectangle())
    }
    
    private var backgroundColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.05)
    }
} 
