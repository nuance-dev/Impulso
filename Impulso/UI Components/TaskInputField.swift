import SwiftUI

struct TaskInputField: View {
    @State private var text = ""
    let onSubmit: (String) -> Void
    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 14))
                .foregroundColor(.secondary.opacity(0.6))
            
            TextField("Press ⌘N or click here to create a task...", text: $text)
                .font(.system(size: 14))
                .textFieldStyle(PlainTextFieldStyle())
                .focused($isFocused)
                .onSubmit(submit)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(colorScheme == .dark ? Color.black.opacity(0.2) : Color.white.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                )
        )
        .onTapGesture {
            isFocused = true
        }
        .keyboardShortcut("n", modifiers: .command)
    }
    
    private func submit() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        text = ""
        onSubmit(trimmed)
    }
}