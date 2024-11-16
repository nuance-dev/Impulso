import Foundation
import UniformTypeIdentifiers
import CoreTransferable

enum BackupFrequency: Int, CaseIterable, Identifiable {
    case never = 0
    case daily = 1
    case weekly = 2
    case monthly = 3
    
    var id: Int { rawValue }
    
    var timeInterval: TimeInterval {
        switch self {
        case .never: return 0
        case .daily: return 86400 // 24 hours
        case .weekly: return 604800 // 7 days
        case .monthly: return 2592000 // 30 days
        }
    }
    
    var description: String {
        switch self {
        case .never: return "Never"
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        }
    }
}

struct BackupRecord: Codable, Identifiable, Equatable {
    let id: UUID
    let date: Date
    let url: URL
    
    init(date: Date, url: URL) {
        self.id = UUID()
        self.date = date
        self.url = url
    }
    
    static func == (lhs: BackupRecord, rhs: BackupRecord) -> Bool {
        lhs.id == rhs.id
    }
}

enum BackupError: LocalizedError {
    case fileNotFound
    case invalidBackup
    case exportFailed
    case importFailed
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "Backup file not found"
        case .invalidBackup:
            return "Invalid backup file"
        case .exportFailed:
            return "Failed to export data"
        case .importFailed:
            return "Failed to import data"
        }
    }
}

// Serializable task data for export/import
struct TaskData: Codable, Identifiable, Equatable {
    let id: UUID
    let description: String
    let createdAt: Date
    let completedAt: Date?
    let order: Int32
    let isFocused: Bool
    let metrics: TaskMetrics?
    let priorityScore: Double
    
    init(from task: ImpulsoTask) {
        self.id = task.id!
        self.description = task.description
        self.createdAt = task.createdAt!
        self.completedAt = task.completedAt
        self.order = task.order
        self.isFocused = task.isFocused
        self.metrics = task.metrics
        self.priorityScore = task.priorityScore
    }
}

@available(iOS 16.0, macOS 13.0, *)
extension TaskData: Transferable {
    public static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(for: TaskData.self, contentType: .taskData)
    }
}

extension UTType {
    static let taskData = UTType(exportedAs: "com.impulso.taskdata")
}
