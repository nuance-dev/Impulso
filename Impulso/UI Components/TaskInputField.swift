import SwiftUI

struct TaskInputField: View {
    @State private var text = ""
    let onSubmit: (String) -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "plus.circle")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            
            TextField("Add a task...", text: $text)
                .font(.system(size: 13))
                .textFieldStyle(PlainTextFieldStyle())
                .submitLabel(.done)
                .onSubmit {
                    submit()
                }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.primary.opacity(0.1))
                )
        )
    }
    
    private var backgroundColor: Color {
        colorScheme == .dark ? Color.black.opacity(0.2) : Color.white.opacity(0.8)
    }
    
    private func submit() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        onSubmit(trimmed)
        text = ""
    }
}