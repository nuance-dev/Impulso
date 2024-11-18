import Foundation
import CoreData
import SwiftUI
import UniformTypeIdentifiers

// MARK: - TaskMetrics Definition
public struct TaskMetrics: Codable, Equatable {
    var impact: MetricValue
    var fun: MetricValue
    var momentum: MetricValue
    var alignment: MetricValue
    var effort: MetricValue
    
    public enum MetricValue: Int, Codable, CaseIterable {
        case unset = 0
        case low = 1
        case medium = 2
        case high = 3
        
        var description: String {
            switch self {
            case .unset: return "Not Set"
            case .low: return "Low"
            case .medium: return "Medium"
            case .high: return "High"
            }
        }
        
        var color: Color {
            switch self {
            case .unset: return .secondary.opacity(0.5)
            case .low: return .yellow
            case .medium: return .orange
            case .high: return .red
            }
        }
    }
    
    init(impact: MetricValue = .medium,
         fun: MetricValue = .medium,
         momentum: MetricValue = .medium,
         alignment: MetricValue = .medium,
         effort: MetricValue = .medium) {
        self.impact = impact
        self.fun = fun
        self.momentum = momentum
        self.alignment = alignment
        self.effort = effort
    }
    
    func value(for type: MetricType) -> MetricValue {
        switch type {
        case .impact: return impact
        case .fun: return fun
        case .momentum: return momentum
        case .alignment: return alignment
        case .effort: return effort
        }
    }
    
    mutating func update(type: MetricType, value: MetricValue) {
        // Validate input value
        guard MetricValue.allCases.contains(value) else {
            print("Warning: Invalid metric value provided")
            return
        }
        
        switch type {
        case .impact: impact = value
        case .fun: fun = value
        case .momentum: momentum = value
        case .alignment: alignment = value
        case .effort: effort = value
        }
    }
}

// MARK: - ImpulsoTask Extensions
extension ImpulsoTask {
    override public var description: String {
        get { taskDescription ?? "" }
        set { taskDescription = newValue }
    }
    
    var metrics: TaskMetrics? {
        get {
            guard let data = metricsData else { return nil }
            return try? JSONDecoder().decode(TaskMetrics.self, from: data)
        }
        set {
            metricsData = try? JSONEncoder().encode(newValue)
        }
    }
}

// MARK: - Fetch Request Helpers
extension ImpulsoTask {
   
    static var allTasksFetchRequest: NSFetchRequest<ImpulsoTask> {
        let request: NSFetchRequest<ImpulsoTask> = ImpulsoTask.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \ImpulsoTask.order, ascending: true)
        ]
        return request
    }
    
    static var activeTasksFetchRequest: NSFetchRequest<ImpulsoTask> {
        let request: NSFetchRequest<ImpulsoTask> = ImpulsoTask.fetchRequest()
        request.predicate = NSPredicate(format: "completedAt == NULL")
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \ImpulsoTask.order, ascending: true)
        ]
        return request
    }
    
    static var completedTasksFetchRequest: NSFetchRequest<ImpulsoTask> {
        let request: NSFetchRequest<ImpulsoTask> = ImpulsoTask.fetchRequest()
        request.predicate = NSPredicate(format: "completedAt != NULL")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ImpulsoTask.completedAt, ascending: false)]
        return request
    }
}

// MARK: - Comparable Conformance
extension ImpulsoTask: Comparable {
    public static func < (lhs: ImpulsoTask, rhs: ImpulsoTask) -> Bool {
        if lhs.isFocused != rhs.isFocused {
            return lhs.isFocused
        }
        return lhs.order < rhs.order
    }
}

extension ImpulsoTask {
    func update(from taskData: TaskData) {
        id = taskData.id
        taskDescription = taskData.description
        createdAt = taskData.createdAt
        completedAt = taskData.completedAt
        order = taskData.order
        isFocused = taskData.isFocused
        isBacklogged = taskData.isBacklogged
        priorityScore = taskData.priorityScore
        
        if let metrics = taskData.metrics {
            self.metrics = metrics
        }
    }
}

public enum MetricType: String, CaseIterable, Identifiable {
    case impact
    case fun
    case momentum
    case alignment
    case effort
    
    public var id: String { rawValue }
    
    var iconName: String {
        switch self {
        case .impact: return "bolt.fill"
        case .fun: return "star.fill"
        case .momentum: return "gauge.medium"
        case .alignment: return "scope"
        case .effort: return "timer"
        }
    }
    
    var color: Color {
        switch self {
        case .impact: return .blue
        case .fun: return .yellow
        case .momentum: return .green
        case .alignment: return .purple
        case .effort: return .red
        }
    }
    
    var title: String {
        switch self {
        case .impact: return "Impact"
        case .fun: return "Fun Factor"
        case .momentum: return "Momentum"
        case .alignment: return "Alignment"
        case .effort: return "Effort"
        }
    }
    
    var shortTitle: String {
        switch self {
        case .impact: return "Impact"
        case .fun: return "Fun"
        case .momentum: return "Flow"
        case .alignment: return "Align"
        case .effort: return "Effort"
        }
    }
    
    var description: String {
        switch self {
        case .impact: return "How much impact will this task have on the project or team?"
        case .fun: return "How enjoyable or engaging is this task?"
        case .momentum: return "Will this task help maintain project momentum?"
        case .alignment: return "How well does this align with current goals?"
        case .effort: return "How much effort is required to complete this?"
        }
    }
}

extension ImpulsoTask {
    var isCompleted: Bool {
        completedAt != nil
    }
}
