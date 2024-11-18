import SwiftUI
import CoreData
import UniformTypeIdentifiers

struct TaskRowView: View {
    let task: ImpulsoTask
    let taskCardHeight: CGFloat
    @Binding var hoveredTaskId: UUID?
    let viewModel: ImpulsoViewModel
    
    var body: some View {
        TaskCardView(
            task: task,
            isHovered: .init(
                get: { hoveredTaskId == task.id },
                set: { _ in }
            ),
            onMetricUpdate: { metrics in
                viewModel.updateTaskMetrics(task, metrics: metrics)
            },
            onFocusToggle: {
                viewModel.toggleTaskFocus(task)
            },
            onComplete: {
                viewModel.completeTask(task)
            },
            onMoveToBacklog: {
                viewModel.moveToBacklog(task)
            }
        )
        .onHover { isHovered in
            hoveredTaskId = isHovered ? task.id : nil
        }
        .frame(height: taskCardHeight)
        .padding(.horizontal)
        .makeDraggable(task: task, draggedTask: Binding(
            get: { viewModel.draggedTask },
            set: { viewModel.draggedTask = $0 }
        ))
        .makeDropArea(
            draggedTask: Binding(
                get: { viewModel.draggedTask },
                set: { viewModel.draggedTask = $0 }
            ),
            tasks: viewModel.tasks,
            onReorder: { tasks in
                guard let sourceIndex = tasks.firstIndex(of: task),
                      let targetIndex = tasks.firstIndex(where: { $0.id == task.id }) else {
                    return
                }
                viewModel.reorderTasks(from: IndexSet(integer: sourceIndex), to: targetIndex)
            }
        )
    }
}
