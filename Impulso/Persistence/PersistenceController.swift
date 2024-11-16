import CoreData
import Foundation

class PersistenceController {
    static let shared = PersistenceController()
    
    let container: NSPersistentContainer
    
    // Local backup directory URL
    private var backupDirectoryURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Backups")
    }
    
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "Impulso")
        
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        // Initialize persistent store
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Failed to load persistent stores: \(error)")
            }
        }
        
        // Configure view context
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        // Setup backup directory
        setupBackupDirectory()
    }
    
    private func setupBackupDirectory() {
        do {
            try FileManager.default.createDirectory(
                at: backupDirectoryURL,
                withIntermediateDirectories: true,
                attributes: nil
            )
        } catch {
            print("Error creating backup directory: \(error)")
        }
    }
    
    // MARK: - Backup Management
    
    func createBackup() async throws -> URL {
        // Create timestamped backup file
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let backupURL = backupDirectoryURL.appendingPathComponent("Impulso_\(timestamp).backup")
        
        // Ensure backup directory exists
        try FileManager.default.createDirectory(
            at: backupDirectoryURL,
            withIntermediateDirectories: true,
            attributes: nil
        )
        
        // Save the context to ensure all changes are persisted
        let context = container.viewContext
        if context.hasChanges {
            try context.save()
        }
        
        // Get the store URL
        guard let storeURL = container.persistentStoreDescriptions.first?.url else {
            throw BackupError.exportFailed
        }
        
        // Copy the store file to backup location
        try FileManager.default.copyItem(at: storeURL, to: backupURL)
        
        return backupURL
    }
    
    func restoreFromBackup(at url: URL) async throws {
        // Verify backup file exists and is valid
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw BackupError.fileNotFound
        }
        
        // Validate backup file
        guard let _ = try? NSPersistentStoreCoordinator.metadataForPersistentStore(
            ofType: NSSQLiteStoreType,
            at: url,
            options: nil
        ) else {
            throw BackupError.invalidBackup
        }
        
        // Save any pending changes
        try container.viewContext.save()
        
        // Remove existing store
        guard let currentStoreURL = container.persistentStoreDescriptions.first?.url else {
            throw BackupError.importFailed
        }
        try container.persistentStoreCoordinator.destroyPersistentStore(
            at: currentStoreURL,
            type: .sqlite
        )
        
        // Copy backup to store location
        try FileManager.default.copyItem(
            at: url,
            to: currentStoreURL
        )
        
        // Reload stores
        container.loadPersistentStores { description, error in
            if let error = error {
                print("Error reloading store: \(error)")
            }
        }
        
        // Reset view context
        container.viewContext.reset()
    }
    
    // MARK: - Import/Export
    
    func exportData() async throws -> URL {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        let fetchRequest: NSFetchRequest<ImpulsoTask> = ImpulsoTask.fetchRequest()
        
        let tasks = try container.viewContext.fetch(fetchRequest)
        let taskData = try encoder.encode(tasks.map(TaskData.init))
        
        let exportURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("Impulso_Export_\(Date().timeIntervalSince1970).json")
        
        try taskData.write(to: exportURL)
        return exportURL
    }
    
    func importData(from url: URL) async throws {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let taskData = try decoder.decode([TaskData].self, from: data)
        
        // Create new background context for import
        let importContext = container.newBackgroundContext()
        
        try await importContext.perform {
            // Create new tasks from imported data
            for taskInfo in taskData {
                let newTask = ImpulsoTask(context: importContext)
                newTask.update(from: taskInfo)
            }
            
            // Save imported tasks
            if importContext.hasChanges {
                try importContext.save()
            }
        }
    }
    
    // MARK: - Utility Methods
    
    func saveContext() {
        let context = container.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                print("Error saving context: \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    func deleteAllData() throws {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = ImpulsoTask.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        deleteRequest.resultType = .resultTypeObjectIDs
        
        let result = try container.persistentStoreCoordinator.execute(deleteRequest, with: container.viewContext) as? NSBatchDeleteResult
        
        if let objectIDs = result?.result as? [NSManagedObjectID] {
            let changes = [NSDeletedObjectsKey: objectIDs]
            NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [container.viewContext])
        }
    }
}
