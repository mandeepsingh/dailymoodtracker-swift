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
    
    init() {
        // Configure StoreKit
        ThemeManager.shared.fetchAvailableProducts()
        
        // Optional: Check if user is on a jailbroken device
        #if !DEBUG
        performJailbreakCheck()
        #endif
    }

    // Add this method if you want to check for jailbreak (optional security measure)
    private func performJailbreakCheck() {
        #if !targetEnvironment(simulator)
        // Simple jailbreak detection (add more comprehensive checks for production)
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: "/Applications/Cydia.app") ||
           fileManager.fileExists(atPath: "/Library/MobileSubstrate/MobileSubstrate.dylib") ||
           fileManager.fileExists(atPath: "/bin/bash") ||
           fileManager.fileExists(atPath: "/usr/sbin/sshd") ||
           fileManager.fileExists(atPath: "/etc/apt") {
            // Device is potentially jailbroken
            print("WARNING: Jailbreak detected")
        }
        #endif
    }
}
