import Foundation
import Combine
import CoreData

enum TaskViewState {
    case active
    case completed
    case backlog
}

class ImpulsoViewModel: ObservableObject {
    enum SortPreference: String, CaseIterable {
        case manual = "Manual"
        case priority = "Priority"
    }
    
    // MARK: - Published Properties
    
    // INPUTS
    @Published var newTaskDescription: String = ""
    @Published var draggedTask: ImpulsoTask?
    @Published var draggedToIndex: Int?
    @Published var sortPreference: SortPreference = .manual
    @Published var currentViewState: TaskViewState = .active {
        didSet {
            fetchTasks()
        }
    }
    
    // OUTPUTS
    @Published private(set) var tasks: [ImpulsoTask] = []
    @Published private(set) var focusedTask: ImpulsoTask?
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var error: Error?
    @Published private(set) var completedTasks: [ImpulsoTask] = []
    @Published private(set) var backlogTasks: [ImpulsoTask] = []
    
    // Add this debug property
    @Published var lastError: String?
    
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
        task.taskDescription = description
        task.createdAt = Date()
        task.order = Int32(tasks.count)
        task.isBacklogged = currentViewState == .backlog
        task.isFocused = false
        
        // Add initial metrics
        task.metrics = TaskMetrics(
            impact: .unset,
            fun: .unset,
            momentum: .unset,
            alignment: .unset,
            effort: .unset
        )
        
        do {
            try context.save()
            print("Task saved successfully: \(description)")
            fetchTasks()
        } catch {
            print("Error saving task: \(error)")
            self.error = error
        }
    }
    
    /// Updates the metrics for a given task
    func updateTaskMetrics(_ task: ImpulsoTask, metrics: TaskMetrics) {
        let context = persistenceController.container.viewContext
        task.metrics = metrics
        
        // Calculate and update priority score
        calculatePriority(for: task)
        
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
        
        let context = persistenceController.container.viewContext
        
        // Update the task's focus state
        task.isFocused = true
        focusedTask = task
        
        do {
            try context.save()
            fetchTasks()
        } catch {
            self.error = error
        }
    }
    
    /// Removes focus from a task
    func unfocusTask(_ task: ImpulsoTask) {
        guard focusedTask?.id == task.id else { return }
        
        let context = persistenceController.container.viewContext
        
        // Update the task's focus state
        task.isFocused = false
        focusedTask = nil
        
        do {
            try context.save()
            updateTaskOrder()
        } catch {
            self.error = error
        }
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
        let context = persistenceController.container.viewContext
        var updatedTasks = tasks
        updatedTasks.move(fromOffsets: source, toOffset: destination)
        
        // Update order of all tasks
        for (index, task) in updatedTasks.enumerated() {
            task.order = Int32(index)
        }
        
        do {
            try context.save()
            fetchTasks()
        } catch {
            self.error = error
        }
    }
    
    /// Toggles the focus state of a task
    func toggleTaskFocus(_ task: ImpulsoTask) {
        let context = persistenceController.container.viewContext
        
        // Toggle the focus state
        task.isFocused = !task.isFocused
        
        // Update focusedTask reference
        if task.isFocused {
            focusedTask = task
        } else {
            focusedTask = nil
        }
        
        do {
            try context.save()
            fetchTasks()
        } catch {
            self.error = error
        }
    }
    
    func moveToBacklog(_ task: ImpulsoTask) {
        let context = persistenceController.container.viewContext
        task.isBacklogged = true
        
        do {
            try context.save()
            fetchTasks()
        } catch {
            self.error = error
        }
    }
    
    func restoreFromBacklog(_ task: ImpulsoTask) {
        let context = persistenceController.container.viewContext
        task.isBacklogged = false
        
        do {
            try context.save()
            fetchTasks()
        } catch {
            self.error = error
        }
    }
    
    func deleteTask(_ task: ImpulsoTask) {
        let context = persistenceController.container.viewContext
        context.delete(task)
        
        do {
            try context.save()
            fetchTasks()
        } catch {
            self.error = error
        }
    }
    
    func updateTaskNotes(_ task: ImpulsoTask, notes: String) {
        let context = persistenceController.container.viewContext
        task.taskNotes = notes.isEmpty ? nil : notes
        
        do {
            try context.save()
            fetchTasks()
        } catch {
            self.error = error
        }
    }
    
    func toggleTaskCompletion(_ task: ImpulsoTask) {
        let context = persistenceController.container.viewContext
        
        if task.completedAt != nil {
            // Uncomplete the task
            task.completedAt = nil
            
            // If the task was focused before completion, restore focus
            if task.isFocused {
                // Unfocus any other focused task first
                if let currentFocused = focusedTask {
                    currentFocused.isFocused = false
                }
                focusedTask = task
            }
        } else {
            // Complete the task
            task.completedAt = Date()
            
            if focusedTask?.id == task.id {
                focusedTask = nil
            }
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
        print("Fetching tasks for state: \(currentViewState)")
        isLoading = true
        
        let fetchRequest: NSFetchRequest<ImpulsoTask> = ImpulsoTask.fetchRequest()
        
        // Set predicate based on current view state
        switch currentViewState {
        case .active:
            fetchRequest.predicate = NSPredicate(format: "completedAt == NULL AND isBacklogged == false")
        case .completed:
            fetchRequest.predicate = NSPredicate(format: "completedAt != NULL")
        case .backlog:
            fetchRequest.predicate = NSPredicate(format: "isBacklogged == true")
        }
        
        // Add appropriate sort descriptors
        switch currentViewState {
        case .completed:
            fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \ImpulsoTask.completedAt, ascending: false)]
        default:
            if sortPreference == .priority {
                fetchRequest.sortDescriptors = [
                    NSSortDescriptor(keyPath: \ImpulsoTask.priorityScore, ascending: false),
                    NSSortDescriptor(keyPath: \ImpulsoTask.order, ascending: true)
                ]
            } else {
                fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \ImpulsoTask.order, ascending: true)]
            }
        }
        
        do {
            tasks = try persistenceController.container.viewContext.fetch(fetchRequest)
            print("Fetched \(tasks.count) tasks")
            isLoading = false
        } catch {
            print("Error fetching tasks: \(error)")
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
    
    // Change these computed properties
    var activeTaskCount: Int {
        tasks.filter { !$0.isCompleted && !$0.isBacklogged }.count
    }
    
    var completedTaskCount: Int {
        tasks.filter { $0.isCompleted }.count
    }
    
    var backlogTaskCount: Int {
        tasks.filter { $0.isBacklogged }.count
    }
}

