// Update your existing App file
import SwiftUI
import CoreData

@main
struct DailyMoodTrackerApp: App {
    let persistenceController = PersistenceController.shared
    
    // Theme manager for in-app purchases
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(themeManager)
        }
    }
}
