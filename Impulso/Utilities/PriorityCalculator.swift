import Foundation

/// Protocol defining the interface for priority calculation
protocol PriorityCalculating {
    func calculatePriority(for metrics: TaskMetrics) -> Double
}

/// Calculates priority scores for tasks based on weighted metrics
struct PriorityCalculator: PriorityCalculating {
    
    // MARK: - Properties
    
    /// Weights for each metric component (total = 1.0)
    private let weights: [String: Double] = [
        "impact": 0.3,    // 30% weight
        "momentum": 0.25, // 25% weight
        "alignment": 0.2, // 20% weight
        "fun": 0.15,     // 15% weight
        "effort": 0.1     // 10% weight
    ]
    
    // MARK: - Public Methods
    
    /// Calculates the priority score for a given set of task metrics
    /// - Parameter metrics: TaskMetrics object containing individual metric values
    /// - Returns: A priority score between 0 and 100
    func calculatePriority(for metrics: TaskMetrics) -> Double {
        // Convert metric values to normalized scores (0-1)
        let impactScore = normalizeMetricValue(metrics.impact)
        let momentumScore = normalizeMetricValue(metrics.momentum)
        let alignmentScore = normalizeMetricValue(metrics.alignment)
        let funScore = normalizeMetricValue(metrics.fun)
        let effortScore = normalizeInvertedMetricValue(metrics.effort)
        
        // Calculate weighted components
        let weightedImpact = impactScore * weights["impact"]!
        let weightedMomentum = momentumScore * weights["momentum"]!
        let weightedAlignment = alignmentScore * weights["alignment"]!
        let weightedFun = funScore * weights["fun"]!
        let weightedEffort = effortScore * weights["effort"]!
        
        // Calculate total priority score
        let totalScore = (weightedImpact +
                         weightedMomentum +
                         weightedAlignment +
                         weightedFun +
                         weightedEffort) * 100
        
        // Round to one decimal place and ensure bounds
        return min(max(round(totalScore * 10) / 10, 0), 100)
    }
    
    // MARK: - Private Methods
    
    private func normalizeMetricValue(_ value: TaskMetrics.MetricValue) -> Double {
        switch value {
        case .high:
            return 1.0
        case .medium:
            return 0.5
        case .low:
            return 0.0
        }
    }
    
    private func normalizeInvertedMetricValue(_ value: TaskMetrics.MetricValue) -> Double {
        switch value {
        case .high:
            return 0.0
        case .medium:
            return 0.5
        case .low:
            return 1.0
        }
    }
}

// MARK: - Usage Example

#if DEBUG
extension PriorityCalculator {
    /// Example usage demonstrating priority calculation
    static func example() {
        let calculator = PriorityCalculator()
        
        let sampleMetrics = TaskMetrics(
            impact: .high,
            fun: .medium,
            momentum: .medium,
            alignment: .high,
            effort: .low
        )
        
        let priority = calculator.calculatePriority(for: sampleMetrics)
        print("Priority Score: \(priority)")
        // Example output: Priority Score: 85.0
    }
}
#endif
