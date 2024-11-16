import SwiftUI

struct TaskInputField: View {
    @State private var text = ""
    let onSubmit: (String) -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "plus.circle")
                .font(.system(size: 12))
                .foregroundColor(.secondary.opacity(0.7))
            
            TextField("Add a task...", text: $text)
                .font(.system(size: 12))
                .textFieldStyle(PlainTextFieldStyle())
                .submitLabel(.done)
                .onSubmit {
                    submit()
                }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.primary.opacity(0.06))
                )
        )
    }
    
    private var backgroundColor: Color {
        colorScheme == .dark ? Color.black.opacity(0.15) : Color.white.opacity(0.7)
    }
    
    private func submit() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        onSubmit(trimmed)
        text = ""
    }
}