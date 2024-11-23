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
    
    init() {
        container = NSPersistentContainer(name: "Impulso")
        
        // Add migration options
        let description = container.persistentStoreDescriptions.first
        description?.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
        description?.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)
        
        // Attempt to load stores with recovery options
        container.loadPersistentStores { description, error in
            if let error = error {
                // First try to recover by removing the store
                print("Error loading persistent stores: \(error)")
                self.attemptStoreRecovery()
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
    
    private func attemptStoreRecovery() {
        guard let url = container.persistentStoreDescriptions.first?.url else { return }
        
        // Remove the existing store
        do {
            try container.persistentStoreCoordinator.destroyPersistentStore(at: url, ofType: NSSQLiteStoreType, options: nil)
            
            // Try to load a fresh store
            container.loadPersistentStores { description, error in
                if let error = error {
                    print("Fatal Error: Failed to recover persistent store: \(error)")
                    fatalError("Failed to recover persistent store: \(error)")
                }
            }
        } catch {
            print("Fatal Error: Failed to destroy persistent store: \(error)")
            fatalError("Failed to destroy persistent store: \(error)")
        }
    }
    
    // Add a method to reset the store (useful for development)
    #if DEBUG
    func resetStore() throws {
        guard let url = container.persistentStoreDescriptions.first?.url else { return }
        try container.persistentStoreCoordinator.destroyPersistentStore(at: url, ofType: NSSQLiteStoreType, options: nil)
        try container.persistentStoreCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: nil)
    }
    #endif
    
    // MARK: - Backup Management
    
    func createBackup() async throws -> URL {
        return try await withCheckedThrowingContinuation { continuation in
            let context = container.newBackgroundContext()
            
            context.performAndWait {
                do {
                    let timestamp = ISO8601DateFormatter().string(from: Date())
                    let backupURL = backupDirectoryURL.appendingPathComponent("Impulso_\(timestamp).backup")
                    
                    try FileManager.default.createDirectory(
                        at: backupDirectoryURL,
                        withIntermediateDirectories: true,
                        attributes: nil
                    )
                    
                    if context.hasChanges {
                        try context.save()
                    }
                    
                    guard let storeURL = container.persistentStoreDescriptions.first?.url else {
                        throw BackupError.exportFailed
                    }
                    
                    try FileManager.default.copyItem(at: storeURL, to: backupURL)
                    continuation.resume(returning: backupURL)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
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
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        let fetchRequest: NSFetchRequest<ImpulsoTask> = ImpulsoTask.fetchRequest()
        let tasks = try container.viewContext.fetch(fetchRequest)
        let taskData = try encoder.encode(tasks.map(TaskData.init))
        
        // Create a unique filename with safe characters
        let timestamp = Date().formatForFilename()
        let filename = "Impulso_Export_\(timestamp).json"
        
        // Use the documents directory instead of temporary
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let exportURL = documentsURL.appendingPathComponent(filename)
        
        try taskData.write(to: exportURL, options: .atomic)
        return exportURL
    }
    
    func importData(from url: URL) async throws {
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw BackupError.fileNotFound
        }
        
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let taskData = try decoder.decode([TaskData].self, from: data)
        
        let importContext = container.newBackgroundContext()
        try await importContext.perform {
            // Clear existing tasks first
            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = ImpulsoTask.fetchRequest()
            let batchDelete = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            try importContext.execute(batchDelete)
            
            // Import new tasks
            for taskInfo in taskData {
                let newTask = ImpulsoTask(context: importContext)
                newTask.update(from: taskInfo)
            }
            
            try importContext.save()
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
