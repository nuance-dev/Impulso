import SwiftUI
import UniformTypeIdentifiers

struct BackupSettingsView: View {
    @ObservedObject var backupManager: BackupManager
    @State private var selectedFrequency: BackupFrequency
    @State private var showingImporter = false
    @State private var showingExporter = false
    @State private var showingDeleteAlert = false
    @State private var selectedBackup: BackupRecord?
    @State private var showingRestoreAlert = false
    @State private var showingSuccessAlert = false
    @State private var successMessage = ""
    @Environment(\.dismiss) private var dismiss
    @State private var backupError: String?
    @State private var showingErrorAlert = false
    
    init(backupManager: BackupManager) {
        self.backupManager = backupManager
        let savedFrequency = BackupFrequency(rawValue: UserDefaults.standard.integer(forKey: "backupFrequency")) ?? .never
        _selectedFrequency = State(initialValue: savedFrequency)
    }
    
    var body: some View {
        Form {
            automaticBackupsSection
            manualBackupSection
            importExportSection
            backupHistorySection
        }
        .navigationTitle("Backup Settings")
        .fileImporter(
            isPresented: $showingImporter,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            handleImport(result)
        }
        .fileExporter(
            isPresented: $showingExporter,
            document: JSONExportDocument(backupManager: backupManager),
            contentType: .json,
            defaultFilename: "Impulso_Export_\(Date().formatForFilename()).json"
        ) { result in
            switch result {
            case .success:
                showSuccess("Data exported successfully")
            case .failure(let error):
                showError(error.localizedDescription)
            }
        }
        .alert("Success", isPresented: $showingSuccessAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(successMessage)
        }
        .alert("Delete Backup", isPresented: $showingDeleteAlert) {
            deleteAlertButtons
        } message: {
            Text("Are you sure you want to delete this backup? This action cannot be undone.")
        }
        .alert("Restore Backup", isPresented: $showingRestoreAlert) {
            restoreAlertButtons
        } message: {
            Text("Are you sure you want to restore this backup? Current data will be replaced.")
        }
        .alert("Backup Failed", isPresented: $showingErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(backupError ?? "Unknown error occurred")
        }
    }
    
    // MARK: - Section Views
    
    private var automaticBackupsSection: some View {
        Section(header: Text("Automatic Backups")) {
            Picker("Backup Frequency", selection: $selectedFrequency) {
                ForEach(BackupFrequency.allCases) { frequency in
                    Text(frequency.description)
                        .tag(frequency)
                }
            }
            .onChange(of: selectedFrequency) { _, frequency in
                backupManager.scheduleAutomaticBackups(frequency: frequency)
            }
            
            if let lastBackup = backupManager.lastBackupDate {
                HStack {
                    Text("Last Backup")
                    Spacer()
                    Text(lastBackup, style: .relative)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private var manualBackupSection: some View {
        Section {
            Button(action: performManualBackup) {
                HStack {
                    Text("Create Backup Now")
                    if backupManager.isBackingUp {
                        Spacer()
                        ProgressView()
                    }
                }
            }
            .disabled(backupManager.isBackingUp)
        }
    }
    
    private var importExportSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 16) {
                Text("Data Transfer")
                    .font(.headline)
                
                HStack(spacing: 12) {
                    Button(action: { showingExporter = true }) {
                        Label("Export Data", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(.bordered)
                    
                    Button(action: { showingImporter = true }) {
                        Label("Import Data", systemImage: "square.and.arrow.down")
                    }
                    .buttonStyle(.bordered)
                    .disabled(backupManager.isBackingUp)
                }
                
                Text("Export your data to transfer between devices or create a backup")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
        }
    }
    
    private var backupHistorySection: some View {
        Section(header: Text("Backup History")) {
            if backupManager.backupHistory.isEmpty {
                Text("No backups available")
                    .foregroundColor(.secondary)
            } else {
                ForEach(backupManager.backupHistory.sorted(by: { $0.date > $1.date })) { record in
                    BackupHistoryRow(record: record) {
                        selectedBackup = record
                        showingRestoreAlert = true
                    } onDelete: {
                        selectedBackup = record
                        showingDeleteAlert = true
                    }
                }
            }
        }
    }
    
    // MARK: - Alert Views
    
    private var deleteAlertButtons: some View {
        Group {
            Button("Delete", role: .destructive) {
                if let backup = selectedBackup {
                    backupManager.deleteBackup(backup)
                }
                selectedBackup = nil
            }
            Button("Cancel", role: .cancel) {
                selectedBackup = nil
            }
        }
    }
    
    private var restoreAlertButtons: some View {
        Group {
            Button("Restore", role: .destructive) {
                if let backup = selectedBackup {
                    Task {
                        do {
                            try await backupManager.restoreFromBackup(backup)
                            dismiss()
                        } catch {
                            print("Restore failed: \(error)")
                        }
                    }
                }
                selectedBackup = nil
            }
            Button("Cancel", role: .cancel) {
                selectedBackup = nil
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func performManualBackup() {
        Task { @MainActor in
            do {
                try await backupManager.performManualBackup()
            } catch {
                backupError = error.localizedDescription
                showingErrorAlert = true
            }
        }
    }
    
    private func handleImport(_ result: Result<[URL], Error>) {
    switch result {
    case .success(let urls):
        guard let url = urls.first else { return }
        
        Task {
            do {
                try await backupManager.persistenceController.importData(from: url)
                await MainActor.run {
                    showSuccess("Data imported successfully")
                }
            } catch {
                await MainActor.run {
                    let errorMessage = error.localizedDescription
                        .replacingOccurrences(of: "The file \"", with: "")
                        .replacingOccurrences(of: "\" couldn't be opened because", with: "")
                    showError("Import failed: \(errorMessage)")
                }
            }
        }
    case .failure(let error):
        showError("Import failed: \(error.localizedDescription)")
    }
}
    
    private func showSuccess(_ message: String) {
        successMessage = message
        showingSuccessAlert = true
    }
    
    private func showError(_ message: String) {
        backupError = message
        showingErrorAlert = true
    }
}

// MARK: - Supporting Types

final class ExportDataContainer {
    var data: Data?
}

struct JSONExportDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    
    let backupManager: BackupManager
    private let container: ExportDataContainer
    
    // Required initializer for FileDocument protocol
    init(configuration: ReadConfiguration) throws {
        self.backupManager = BackupManager(persistenceController: PersistenceController.shared)
        self.container = ExportDataContainer()
    }
    
    // Custom initializer for our use
    init(backupManager: BackupManager) {
        self.backupManager = backupManager
        self.container = ExportDataContainer()
        
        // Start data preparation without capturing self
        let manager = backupManager
        let dataContainer = container
        Task {
            do {
                let exportURL = try await manager.persistenceController.exportData()
                dataContainer.data = try Data(contentsOf: exportURL)
            } catch {
                print("Failed to prepare export data: \(error.localizedDescription)")
            }
        }
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        guard let data = container.data else {
            throw BackupError.exportFailed
        }
        return FileWrapper(regularFileWithContents: data)
    }
}

struct BackupHistoryRow: View {
    let record: BackupRecord
    let onRestore: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(record.date, style: .date)
                    .font(.headline)
                Text(record.date, style: .time)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button("Restore", action: onRestore)
                .buttonStyle(.borderless)
            
            Button(role: .destructive, action: onDelete) {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
        }
        .padding(.vertical, 4)
    }
}

// Add this extension to format dates for filenames
extension Date {
    func formatForFilename() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmmss"
        return formatter.string(from: self)
    }
}
