import Foundation
import Combine
import CoreData

class ImpulsoViewModel: ObservableObject {
    // MARK: - Published Properties
    
    // INPUTS
    @Published var newTaskDescription: String = ""
    @Published var draggedTask: ImpulsoTask?
    @Published var draggedToIndex: Int?
    
    // OUTPUTS
    @Published private(set) var tasks: [ImpulsoTask] = []
    @Published private(set) var focusedTask: ImpulsoTask?
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var error: Error?
    
    // MARK: - Dependencies
    
    private let persistenceController: PersistenceController
    private let priorityCalculator: PriorityCalculator
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(persistenceController: PersistenceController, priorityCalculator: PriorityCalculator) {
        self.persistenceController = persistenceController
        self.priorityCalculator = priorityCalculator
        
        setupSubscriptions()
        fetchTasks()
    }
    
    // MARK: - Public Interface
    
    /// Adds a new task with the given description
    func addTask(description: String) {
        guard !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let context = persistenceController.container.viewContext
        let task = ImpulsoTask(context: context)
        task.id = UUID()
        task.description = description
        task.createdAt = Date()
        task.order = Int32(tasks.count)
        
        do {
            try context.save()
            fetchTasks()
            newTaskDescription = ""
        } catch {
            self.error = error
        }
    }
    
    /// Updates the metrics for a given task
    func updateTaskMetrics(_ task: ImpulsoTask, metrics: TaskMetrics) {
        let context = persistenceController.container.viewContext
        task.metrics = metrics
        
        do {
            try context.save()
            fetchTasks()
        } catch {
            self.error = error
        }
    }
    
    /// Sets focus on a specific task
    func focusTask(_ task: ImpulsoTask) {
        guard focusedTask?.id != task.id else { return }
        
        focusedTask = task
        updateTaskOrder()
    }
    
    /// Removes focus from a task
    func unfocusTask(_ task: ImpulsoTask) {
        guard focusedTask?.id == task.id else { return }
        
        focusedTask = nil
        updateTaskOrder()
    }
    
    /// Marks a task as completed
    func completeTask(_ task: ImpulsoTask) {
        let context = persistenceController.container.viewContext
        
        task.completedAt = Date()
        
        if focusedTask?.id == task.id {
            focusedTask = nil
        }
        
        do {
            try context.save()
            fetchTasks()
        } catch {
            self.error = error
        }
    }
    
    /// Reorders tasks based on drag and drop operation
    func reorderTasks(from source: IndexSet, to destination: Int) {
        var updatedTasks = tasks
        updatedTasks.move(fromOffsets: source, toOffset: destination)
        
        // Update order of all tasks
        for (index, task) in updatedTasks.enumerated() {
            task.order = Int32(index)
        }
        
        do {
            try persistenceController.container.viewContext.save()
            fetchTasks()
        } catch {
            self.error = error
        }
    }
    
    /// Toggles the focus state of a task
    func toggleTaskFocus(_ task: ImpulsoTask) {
        let context = persistenceController.container.viewContext
        
        // Toggle the focus state
        if task.isFocused {
            unfocusTask(task)
        } else {
            focusTask(task)
        }
        
        do {
            try context.save()
            fetchTasks()
        } catch {
            self.error = error
        }
    }
    
    // MARK: - Private Implementation
    
    private func setupSubscriptions() {
        // Monitor drag and drop operations
        $draggedTask
            .combineLatest($draggedToIndex)
            .filter { task, index in
                task != nil && index != nil
            }
            .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
            .sink { [weak self] task, index in
                guard let task = task, let index = index else { return }
                self?.handleDragAndDrop(task: task, toIndex: index)
            }
            .store(in: &cancellables)
    }
    
    private func handleDragAndDrop(task: ImpulsoTask, toIndex: Int) {
        guard let currentIndex = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        let sourceIndex = IndexSet(integer: currentIndex)
        reorderTasks(from: sourceIndex, to: toIndex)
        
        // Reset drag state
        draggedTask = nil
        draggedToIndex = nil
    }
    
    private func fetchTasks() {
        isLoading = true
        
        let fetchRequest: NSFetchRequest<ImpulsoTask> = ImpulsoTask.fetchRequest()
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(keyPath: \ImpulsoTask.order, ascending: true)
        ]
        fetchRequest.predicate = NSPredicate(format: "completedAt == NULL")
        
        do {
            tasks = try persistenceController.container.viewContext.fetch(fetchRequest)
            isLoading = false
        } catch {
            self.error = error
            isLoading = false
        }
    }
    
    private func calculatePriority(for task: ImpulsoTask) {
        if let metrics = task.metrics {
            task.priorityScore = priorityCalculator.calculatePriority(for: metrics)
        }
    }
    
    private func updateTaskOrder() {
        var updatedTasks = tasks
        
        // If there's a focused task, move it to the top
        if let focusedTask = focusedTask,
           let currentIndex = updatedTasks.firstIndex(where: { $0.id == focusedTask.id }) {
            updatedTasks.move(fromOffsets: IndexSet(integer: currentIndex), toOffset: 0)
        }
        
        // Update order of all tasks
        for (index, task) in updatedTasks.enumerated() {
            task.order = Int32(index)
        }
        
        do {
            try persistenceController.container.viewContext.save()
            fetchTasks()
        } catch {
            self.error = error
        }
    }
    
    private func saveContext() {
        do {
            try persistenceController.container.viewContext.save()
        } catch {
            self.error = error
        }
    }
}

