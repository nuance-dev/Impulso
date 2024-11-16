import Foundation
import CoreData

@objc(ImpulsoTask)
public class ImpulsoTask: NSManagedObject {
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        id = UUID()
        createdAt = Date()
        order = 0
        isFocused = false
        priorityScore = 0.0
    }
}

extension ImpulsoTask {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ImpulsoTask> {
        return NSFetchRequest<ImpulsoTask>(entityName: "ImpulsoTask")
    }
    
    @NSManaged public var id: UUID
    @NSManaged public var taskDescription: String
    @NSManaged public var createdAt: Date
    @NSManaged public var completedAt: Date?
    @NSManaged public var order: Int32
    @NSManaged public var isFocused: Bool
    @NSManaged public var metricsData: Data?
    @NSManaged public var priorityScore: Double
}