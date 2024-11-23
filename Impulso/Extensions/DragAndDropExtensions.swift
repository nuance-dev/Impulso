import SwiftUI
import CoreData

// MARK: - Drag and Drop Extensions
extension View {
    /// Makes a view draggable by adding drag gesture handlers
    /// - Parameters:
    ///   - task: Task to make draggable
    ///   - draggedTask: Binding to currently dragged task
    func makeDraggable(task: ImpulsoTask, draggedTask: Binding<ImpulsoTask?>) -> some View {
        self.modifier(DraggableModifier(task: task, draggedTask: draggedTask))
    }
    
    /// Makes a view act as a drop area for tasks
    /// - Parameters:
    ///   - draggedTask: Currently dragged task
    ///   - tasks: Array of tasks
    ///   - onReorder: Closure called when tasks are reordered
    func makeDropArea(draggedTask: Binding<ImpulsoTask?>, tasks: [ImpulsoTask], onReorder: @escaping ([ImpulsoTask]) -> Void) -> some View {
        self.modifier(DropAreaModifier(draggedTask: draggedTask, tasks: tasks, onReorder: onReorder))
    }
}

// MARK: - Draggable Modifier
private struct DraggableModifier: ViewModifier {
    let task: ImpulsoTask
    @Binding var draggedTask: ImpulsoTask?
    @State private var dragOffset: CGSize = .zero
    @State private var initialPosition: CGPoint = .zero
    
    func body(content: Content) -> some View {
        content
            .offset(x: dragOffset.width, y: dragOffset.height)
            .zIndex(draggedTask?.id == task.id ? 1 : 0)
            .gesture(
                DragGesture(coordinateSpace: .global)
                    .onChanged { value in
                        if draggedTask == nil {
                            draggedTask = task
                            initialPosition = CGPoint(x: value.startLocation.x, y: value.startLocation.y)
                        }
                        
                        let translation = CGSize(
                            width: value.translation.width,
                            height: value.translation.height
                        )
                        
                        withAnimation(.interactiveSpring()) {
                            dragOffset = translation
                        }
                    }
                    .onEnded { _ in
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            dragOffset = .zero
                            draggedTask = nil
                        }
                    }
            )
            .opacity(draggedTask?.id == task.id ? 0.8 : 1.0)
            .scaleEffect(draggedTask?.id == task.id ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: draggedTask)
    }
}

// MARK: - Drop Area Modifier
private struct DropAreaModifier: ViewModifier {
    @Binding var draggedTask: ImpulsoTask?
    let tasks: [ImpulsoTask]
    let onReorder: ([ImpulsoTask]) -> Void
    
    @State private var targetIndex: Int?
    
    func body(content: Content) -> some View {
        content
            .onDrop(of: [.text], delegate: TaskDropDelegate(
                draggedTask: $draggedTask,
                tasks: tasks,
                targetIndex: $targetIndex,
                onReorder: onReorder
            ))
    }
}

// MARK: - Drop Delegate
private struct TaskDropDelegate: DropDelegate {
    @Binding var draggedTask: ImpulsoTask?
    let tasks: [ImpulsoTask]
    @Binding var targetIndex: Int?
    let onReorder: ([ImpulsoTask]) -> Void
    
    func performDrop(info: DropInfo) -> Bool {
        guard let draggedTask = draggedTask,
              let fromIndex = tasks.firstIndex(where: { $0.id == draggedTask.id }),
              let toIndex = targetIndex else {
            return false
        }
        
        DispatchQueue.main.async {
            var updatedTasks = tasks
            updatedTasks.remove(at: fromIndex)
            updatedTasks.insert(draggedTask, at: toIndex)
            
            onReorder(updatedTasks)
            self.draggedTask = nil
            self.targetIndex = nil
        }
        
        return true
    }
    
    func dropEntered(info: DropInfo) {
        guard let draggedTask = draggedTask else { return }
        
        let location = info.location
        
        // Find the target index based on the drop location
        for (index, task) in tasks.enumerated() {
            guard task.id != draggedTask.id else { continue }
            
            // Update target index if we're in the task's bounds
            if isLocation(location, inTaskBounds: index) {
                targetIndex = index
                break
            }
        }
    }
    
    func dropExited(info: DropInfo) {
        targetIndex = nil
    }
    
    func validateDrop(info: DropInfo) -> Bool {
        return true
    }
    
    // Helper to determine if a location is within a task's bounds
    private func isLocation(_ location: CGPoint, inTaskBounds index: Int) -> Bool {
        let taskHeight: CGFloat = 44 // Standard row height
        let spacing: CGFloat = 6 // Matches spacing in ImpulsoView
        let verticalPadding: CGFloat = 8 // Matches TaskCardView padding
        
        let totalItemHeight = taskHeight + spacing + (verticalPadding * 2)
        let yPosition = CGFloat(index) * totalItemHeight
        
        // Add buffer zone for better drop targeting
        let buffer: CGFloat = spacing / 2
        return location.y >= (yPosition - buffer) && location.y <= (yPosition + totalItemHeight + buffer)
    }
}

struct StateDropAreaModifier: ViewModifier {
    let state: TaskViewState
    let viewModel: ImpulsoViewModel
    @State private var isTargeted = false
    
    func body(content: Content) -> some View {
        content
            .onDrop(of: [.text], delegate: StateDropDelegate(
                targetState: state,
                viewModel: viewModel,
                isTargeted: $isTargeted
            ))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.blue.opacity(isTargeted ? 0.3 : 0),
                           lineWidth: 2)
                    .animation(.easeOut(duration: 0.2), value: isTargeted)
            )
    }
}

struct StateDropDelegate: DropDelegate {
    let targetState: TaskViewState
    let viewModel: ImpulsoViewModel
    @Binding var isTargeted: Bool
    
    func performDrop(info: DropInfo) -> Bool {
        guard let draggedTask = viewModel.draggedTask else { return false }
        
        // Don't allow dropping into completed state
        if targetState == .completed { return false }
        
        withAnimation(.spring(response: 0.3)) {
            viewModel.moveTaskToState(draggedTask, state: targetState)
            viewModel.draggedTask = nil
            viewModel.draggedToIndex = nil
            isTargeted = false
        }
        
        return true
    }
    
    func dropEntered(info: DropInfo) {
        guard viewModel.draggedTask != nil else { return }
        withAnimation(.easeOut(duration: 0.2)) {
            isTargeted = true
        }
    }
    
    func dropExited(info: DropInfo) {
        withAnimation(.easeOut(duration: 0.2)) {
            isTargeted = false
        }
    }
    
    func validateDrop(info: DropInfo) -> Bool {
        guard let draggedTask = viewModel.draggedTask else { return false }
        return targetState.dropAllowed
    }
}
