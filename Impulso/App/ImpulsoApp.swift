import SwiftUI
import AppKit

@main
struct ImpulsoApp: App {
    @AppStorage("isDarkMode") private var isDarkMode = false
    @StateObject private var menuBarController = MenuBarController()
    @State private var showingUpdateSheet = false
    @StateObject private var backupManager: BackupManager
    
    // Initialize persistence controller
    private let persistenceController = PersistenceController.shared
    
    init() {
        // Initialize backup manager
        let backup = BackupManager(persistenceController: persistenceController)
        _backupManager = StateObject(wrappedValue: backup)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(isDarkMode ? .dark : .light)
                .background(WindowAccessor())
                .environmentObject(menuBarController)
                .environmentObject(backupManager)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .sheet(isPresented: $showingUpdateSheet) {
                    MenuBarView(updater: menuBarController.updater)
                        .environmentObject(menuBarController)
                }
                .onAppear {
                    menuBarController.updater.checkForUpdates()
                    menuBarController.updater.onUpdateAvailable = {
                        showingUpdateSheet = true
                    }
                }
        }
        .windowStyle(HiddenTitleBarWindowStyle())
        .commands {
            CommandGroup(replacing: .newItem) {
        // Empty group to disable default Command+N
    }
        }
        
        Settings {
            BackupSettingsView(backupManager: backupManager)
        }
    }

    @MainActor
    private func performBackup() {
        Task {
            try? await backupManager.performManualBackup()
        }
    }
}
