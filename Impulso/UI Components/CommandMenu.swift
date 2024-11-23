import SwiftUI

struct CommandMenu: View {
    @Binding var isPresented: Bool
    let onSubmit: (String) -> Void
    @State private var text = ""
    @State private var filteredTasks: [ImpulsoTask] = []
    @FocusState private var isFocused: Bool
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.managedObjectContext) private var viewContext
    @State private var searchDebouncer: Timer?
    
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
                    .onChange(of: text) { _, newValue in
                        debouncedSearch(newValue)
                    }
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
            
            ScrollView {
                VStack(alignment: .leading, spacing: 2) {
                    if text.isEmpty {
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
                    } else {
                        ForEach(filteredTasks) { task in
                            Button(action: {
                                task.isFocused = true
                                try? viewContext.save()
                                isPresented = false
                            }) {
                                HStack {
                                    Text(task.taskDescription ?? "")
                                        .font(.system(size: 14))
                                    Spacer()
                                    if task.isFocused {
                                        Image(systemName: "star.fill")
                                            .font(.system(size: 12))
                                            .foregroundColor(.yellow)
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(CommandMenuButtonStyle())
                        }
                        
                        if filteredTasks.isEmpty {
                            Button(action: {
                                onSubmit(text)
                                isPresented = false
                            }) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(.blue)
                                    Text("Create \"\(text)\"")
                                    Spacer()
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                            }
                            .buttonStyle(CommandMenuButtonStyle())
                        }
                    }
                }
            }
            .frame(maxHeight: 300)
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
        .onDisappear {
            searchDebouncer?.invalidate()
            searchDebouncer = nil
        }
    }
    
    private func filterTasks(query: String) {
        guard !query.isEmpty else {
            filteredTasks = []
            return
        }
        
        let fetchRequest: NSFetchRequest<ImpulsoTask> = ImpulsoTask.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "taskDescription CONTAINS[cd] %@", query
        )
        fetchRequest.fetchLimit = 5
        
        do {
            filteredTasks = try viewContext.fetch(fetchRequest)
        } catch {
            print("Error filtering tasks: \(error)")
            filteredTasks = []
        }
    }
    
    private func debouncedSearch(_ query: String) {
        searchDebouncer?.invalidate()
        searchDebouncer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
            filterTasks(query: query)
            searchDebouncer = nil
        }
    }
}

struct CommandMenuButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var colorScheme
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                configuration.isPressed ? 
                    (colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.05)) : 
                    Color.clear
            )
            .contentShape(Rectangle())
    }
} 
