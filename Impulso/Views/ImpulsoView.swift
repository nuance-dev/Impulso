import SwiftUI

struct ImpulsoView: View {
    @ObservedObject var viewModel: ImpulsoViewModel
    @State private var hoveredTaskId: UUID?
    
    var body: some View {
        VStack(spacing: 16) {
            if viewModel.tasks.isEmpty {
                emptyStateView
            } else {
                HStack {
                    Spacer()
                    SortToggle(sortPreference: $viewModel.sortPreference)
                }
                .padding(.horizontal)
                
                ScrollView {
                    LazyVStack(spacing: 6) {
                        ForEach(viewModel.tasks) { task in
                            TaskCardView(
                                task: task,
                                isHovered: .init(
                                    get: { hoveredTaskId == task.id },
                                    set: { _ in }
                                ),
                                onMetricUpdate: { viewModel.updateTaskMetrics(task, metrics: $0) },
                                onFocusToggle: { viewModel.toggleTaskFocus(task) },
                                onComplete: { viewModel.completeTask(task) }
                            )
                            .onHover { isHovered in
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    hoveredTaskId = isHovered ? task.id : nil
                                }
                            }
                            .makeDraggable(task: task, draggedTask: .init(
                                get: { viewModel.draggedTask },
                                set: { viewModel.draggedTask = $0 }
                            ))
                            .makeDropArea(
                                draggedTask: .init(
                                    get: { viewModel.draggedTask },
                                    set: { viewModel.draggedTask = $0 }
                                ),
                                tasks: viewModel.tasks
                            ) { updatedTasks in
                                if let sourceIndex = updatedTasks.firstIndex(where: { $0.id == task.id }),
                                   let targetIndex = viewModel.tasks.firstIndex(where: { $0.id == task.id }) {
                                    viewModel.reorderTasks(from: IndexSet(integer: sourceIndex), to: targetIndex)
                                }
                            }
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .padding(.vertical, 12)
                }
                
                Divider()
                    .opacity(0.3)
            }
            
            TaskInputField(onSubmit: viewModel.addTask)
        }
        .padding(16)
        .background(
            VisualEffectBlur(material: .contentBackground, blendingMode: .behindWindow)
                .overlay(
                    Color.primary.opacity(0.03)
                )
        )
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "square.and.pencil")
                .font(.system(size: 32))
                .foregroundColor(.secondary.opacity(0.4))
            Text("Add your first task")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct SortToggle: View {
    @Binding var sortPreference: ImpulsoViewModel.SortPreference
    
    var body: some View {
        Menu {
            ForEach(ImpulsoViewModel.SortPreference.allCases, id: \.self) { preference in
                Button(action: {
                    sortPreference = preference
                }) {
                    HStack {
                        Text(preference.rawValue)
                        if sortPreference == preference {
                            Image(systemName: "checkmark")
                                .font(.system(size: 10))
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "arrow.up.arrow.down")
                    .font(.system(size: 10, weight: .light))
                Text(sortPreference.rawValue)
                    .font(.system(size: 11))
            }
            .foregroundColor(.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(4)
        }
    }
}
