import SwiftUI

struct ImpulsoView: View {
    @ObservedObject var viewModel: ImpulsoViewModel
    @State private var hoveredTaskId: UUID?
    
    var body: some View {
        VStack(spacing: 16) {
            if viewModel.tasks.isEmpty {
                emptyStateView
            } else {
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
