import SwiftUI

struct ImpulsoView: View {
    @ObservedObject var viewModel: ImpulsoViewModel
    @State private var hoveredTaskId: UUID?
    
    var body: some View {
        VStack(spacing: 24) {
            if viewModel.tasks.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
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
                    .padding(.vertical, 16)
                    .animation(.spring(response: 0.3), value: viewModel.tasks)
                }
                
                Divider()
                    .padding(.horizontal, -20)
            }
            
            TaskInputField(onSubmit: viewModel.addTask)
        }
        .padding(20)
        .background(VisualEffectBlur(material: .contentBackground, blendingMode: .behindWindow))
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
