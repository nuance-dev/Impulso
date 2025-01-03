import SwiftUI
import CoreData
import UniformTypeIdentifiers

struct TaskRowView: View {
    let task: ImpulsoTask
    let taskCardHeight: CGFloat
    @Binding var hoveredTaskId: UUID?
    let viewModel: ImpulsoViewModel
    @State private var expandedHeight: CGFloat = 0
    
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
                viewModel.toggleTaskCompletion(task)
            },
            onMoveToBacklog: {
                if task.isBacklogged {
                    viewModel.restoreFromBacklog(task)
                } else {
                    viewModel.moveToBacklog(task)
                }
            },
            onDelete: {
                viewModel.deleteTask(task)
            },
            onNotesUpdate: { notes in
                viewModel.updateTaskNotes(task, notes: notes!)
            },
            onExpandedHeightChange: { height in
                withAnimation(.spring(response: 0.3)) {
                    expandedHeight = height
                }
            }
        )
        .onHover { isHovered in
            hoveredTaskId = isHovered ? task.id : nil
        }
        .frame(minHeight: taskCardHeight + expandedHeight)
        .padding(.horizontal)
        .opacity(viewModel.draggedTask?.id == task.id ? 0.3 : 1)
        .animation(.easeInOut(duration: 0.2), value: viewModel.draggedTask?.id)
        .onDrag {
            if viewModel.draggedTask == nil {
                withAnimation(.easeOut(duration: 0.2)) {
                    viewModel.draggedTask = task
                }
            }
            return NSItemProvider(object: task.id!.uuidString as NSString)
        }
        .onDrop(of: [.text], delegate: TaskDropDelegate(
            task: task,
            viewModel: viewModel
        ))
    }
}

private struct TaskDropDelegate: DropDelegate {
    let task: ImpulsoTask
    let viewModel: ImpulsoViewModel
    
    func performDrop(info: DropInfo) -> Bool {
        guard let draggedTask = viewModel.draggedTask,
              let fromIndex = viewModel.tasks.firstIndex(where: { $0.id == draggedTask.id }),
              let toIndex = viewModel.tasks.firstIndex(where: { $0.id == task.id }) else {
            return false
        }
        
        viewModel.reorderTasks(from: IndexSet(integer: fromIndex), to: toIndex)
        viewModel.draggedTask = nil
        return true
    }
    
    func dropEntered(info: DropInfo) {
        guard let draggedTask = viewModel.draggedTask,
              draggedTask.id != task.id else { return }
        
        let fromIndex = viewModel.tasks.firstIndex(where: { $0.id == draggedTask.id })!
        let toIndex = viewModel.tasks.firstIndex(where: { $0.id == task.id })!
        
        if fromIndex != toIndex {
            withAnimation(.easeInOut(duration: 0.3)) {
                viewModel.reorderTasks(from: IndexSet(integer: fromIndex), to: toIndex)
            }
        }
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }
}
