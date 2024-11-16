import SwiftUI

struct ImpulsoView: View {
    @ObservedObject var viewModel: ImpulsoViewModel
    @State private var showingCommandMenu = false
    @State private var hoveredTaskId: UUID?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                TaskViewSelector(selection: $viewModel.currentViewState)
                Spacer()
                
                Button(action: { showingCommandMenu = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "magnifyingglass")
                        Text("Search")
                        Text("⌘K")
                            .foregroundColor(.secondary)
                    }
                    .font(.system(size: 13))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(6)
                }
                .buttonStyle(PlainButtonStyle())
                .keyboardShortcut("k", modifiers: .command)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            
            Divider()
            
            // Add error display
            if let error = viewModel.error {
                Text("Error: \(error.localizedDescription)")
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding()
            }
            
            // Add loading indicator
            if viewModel.isLoading {
                ProgressView()
                    .padding()
            }
            
            // Add TaskInputField here
            TaskInputField(onSubmit: viewModel.addTask)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            
            // Task List
            if viewModel.tasks.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    LazyVStack(spacing: 1) {
                        ForEach(viewModel.tasks) { task in
                            TaskRowView(
                                task: task,
                                taskCardHeight: 44,
                                hoveredTaskId: $hoveredTaskId,
                                viewModel: viewModel
                            )
                        }
                    }
                }
            }
        }
        .overlay {
            if showingCommandMenu {
                Color.black.opacity(0.2)
                    .ignoresSafeArea()
                    .onTapGesture {
                        showingCommandMenu = false
                    }
                
                CommandMenu(isPresented: $showingCommandMenu, onSubmit: viewModel.addTask)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(
            VisualEffectBlur(material: .contentBackground, blendingMode: .behindWindow)
        )
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: emptyStateIcon)
                .font(.system(size: 32))
                .foregroundColor(.secondary.opacity(0.4))
            Text(emptyStateMessage)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyStateIcon: String {
        switch viewModel.currentViewState {
        case .active: return "square.and.pencil"
        case .completed: return "checkmark.circle"
        case .backlog: return "archivebox"
        }
    }
    
    private var emptyStateMessage: String {
        switch viewModel.currentViewState {
        case .active: return "Add your first task"
        case .completed: return "No completed tasks"
        case .backlog: return "Your backlog is empty"
        }
    }
}

struct SortToggle: View {
    @Binding var sortPreference: ImpulsoViewModel.SortPreference
    
    var body: some View {
        Toggle(isOn: Binding(
            get: { sortPreference == .priority },
            set: { sortPreference = $0 ? .priority : .manual }
        )) {
            Text("Sort by Priority")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .toggleStyle(.checkbox)
        .padding(.horizontal, 8)
    }
}
