import Foundation
import Combine

class BackupManager: ObservableObject {
    @Published private(set) var lastBackupDate: Date?
    @Published private(set) var backupHistory: [BackupRecord] = []
    @Published private(set) var isBackingUp: Bool = false
    
    let persistenceController: PersistenceController
    private var backupTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    init(persistenceController: PersistenceController) {
        self.persistenceController = persistenceController
        self.backupHistory = []
        self.backupHistory = self.loadBackupHistory()
        self.setupAutomaticBackups()
    }
    
    // MARK: - Public Methods
    
    func scheduleAutomaticBackups(frequency: BackupFrequency) {
        UserDefaults.standard.set(frequency.rawValue, forKey: "backupFrequency")
        setupAutomaticBackups()
    }
    
    func performManualBackup() async throws {
        guard !isBackingUp else { return }
        
        isBackingUp = true
        defer { isBackingUp = false }
        
        let backupURL = try await persistenceController.createBackup()
        let record = BackupRecord(date: Date(), url: backupURL)
        
        await MainActor.run {
            backupHistory.append(record)
            saveBackupHistory()
            lastBackupDate = Date()
        }
    }
    
    func restoreFromBackup(_ record: BackupRecord) async throws {
        guard FileManager.default.fileExists(atPath: record.url.path) else {
            throw BackupError.fileNotFound
        }
        
        try await persistenceController.restoreFromBackup(at: record.url)
    }
    
    func deleteBackup(_ record: BackupRecord) {
        do {
            try FileManager.default.removeItem(at: record.url)
            backupHistory.removeAll { $0.id == record.id }
            saveBackupHistory()
        } catch {
            print("Error deleting backup: \(error)")
        }
    }
    
    // MARK: - Private Methods
    
    private func setupAutomaticBackups() {
        backupTimer?.invalidate()
        
        guard let frequency = BackupFrequency(rawValue: UserDefaults.standard.integer(forKey: "backupFrequency")),
              frequency != .never else { return }
        
        backupTimer = Timer.scheduledTimer(
            withTimeInterval: frequency.timeInterval,
            repeats: true
        ) { [weak self] _ in
            guard let self = self else { return }
            
            Task {
                do {
                    try await self.performManualBackup()
                } catch {
                    print("Automatic backup failed: \(error)")
                }
            }
        }
    }
    
    private func loadBackupHistory() -> [BackupRecord] {
        guard let data = UserDefaults.standard.data(forKey: "backupHistory"),
              let history = try? JSONDecoder().decode([BackupRecord].self, from: data) else {
            return []
        }
        
        // Filter out records for backups that no longer exist
        return history.filter { FileManager.default.fileExists(atPath: $0.url.path) }
    }
    
    private func saveBackupHistory() {
        if let data = try? JSONEncoder().encode(backupHistory) {
            UserDefaults.standard.set(data, forKey: "backupHistory")
        }
    }
    
    deinit {
        backupTimer?.invalidate()
    }
}
