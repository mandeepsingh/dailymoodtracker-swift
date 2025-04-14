// Update your existing App file
import SwiftUI
import CoreData

// In your App.swift file
@main
struct DailyMoodTrackerApp: App {
    let persistenceController = PersistenceController.shared
    
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environment(\.themeColors, themeManager.currentThemeColors)
                .environmentObject(themeManager)
                // Remove the preferredColorScheme modifier
        }
    }
}
