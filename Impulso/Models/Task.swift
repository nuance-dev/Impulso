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
        case low = 1
        case medium = 2
        case high = 3
        
        var description: String {
            switch self {
            case .low: return "Low"
            case .medium: return "Medium"
            case .high: return "High"
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
        get { taskDescription }
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
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ImpulsoTask> {
        return NSFetchRequest<ImpulsoTask>(entityName: "ImpulsoTask")
    }
    
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
    func update(from data: TaskData) {
        self.id = data.id
        self.description = data.description
        self.createdAt = data.createdAt
        self.completedAt = data.completedAt
        self.order = data.order
        self.isFocused = data.isFocused
        self.metrics = data.metrics
        self.priorityScore = data.priorityScore
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
        case .momentum: return "speedometer"
        case .alignment: return "arrow.up.right"
        case .effort: return "clock.fill"
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
}

extension ImpulsoTask {
    var isCompleted: Bool {
        completedAt != nil
    }
}

extension ImpulsoTask: Identifiable {
    // No implementation needed since we already have an `id` property
    // that matches the requirements of Identifiable
}
