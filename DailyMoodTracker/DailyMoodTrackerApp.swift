import SwiftUI
import CoreData
import UIKit

// Create a UIApplicationDelegate class for additional configuration
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // Configure for iPad
        if UIDevice.current.userInterfaceIdiom == .pad {
            // Set supported orientations
            UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
        }
        return true
    }
}

@main
struct DailyMoodTrackerApp: App {
    // Connect the AppDelegate
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    let persistenceController = PersistenceController.shared
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some Scene {
        WindowGroup {
            // Use modified ContentView with proper navigation structure
            ModifiedContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environment(\.themeColors, themeManager.currentThemeColors)
                .environmentObject(themeManager)
        }
    }
    
    init() {
        // Configure StoreKit
        ThemeManager.shared.fetchAvailableProducts()
        
        // Configure navigation bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        
        // Configure tab bar appearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        UITabBar.appearance().standardAppearance = tabBarAppearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        }
        
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

// A modified ContentView that properly handles iPad navigation
struct ModifiedContentView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        // Check if we're on iPad
        if UIDevice.current.userInterfaceIdiom == .pad {
            // iPad layout with proper navigation
            TabView {
                NavigationView {
                    EntryView()
                }
                .navigationViewStyle(StackNavigationViewStyle()) // Force full-screen navigation
                .tabItem {
                    Label("New Entry", systemImage: "plus.circle")
                }
                
                NavigationView {
                    HistoryView()
                }
                .navigationViewStyle(StackNavigationViewStyle())
                .tabItem {
                    Label("History", systemImage: "list.bullet")
                }
                
                NavigationView {
                    TrendsView()
                }
                .navigationViewStyle(StackNavigationViewStyle())
                .tabItem {
                    Label("Trends", systemImage: "chart.line.uptrend.xyaxis")
                }
                
                NavigationView {
                    SettingsView()
                }
                .navigationViewStyle(StackNavigationViewStyle())
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
            }
            .accentColor(themeManager.currentThemeColors.tabBarSelected)
            .onAppear {
                // Configure tab bar appearance for iPad
                updateTabBarAppearance()
            }
            .onChange(of: themeManager.currentTheme) { _ in
                updateTabBarAppearance()
            }
        } else {
            // Regular iPhone layout - keep using your original ContentView
            ContentView()
        }
    }
    
    private func updateTabBarAppearance() {
        // Get colors from theme
        let backgroundColor = UIColor(themeManager.currentThemeColors.tabBarBackground)
        let selectedColor = UIColor(themeManager.currentThemeColors.tabBarSelected)
        let unselectedColor = UIColor(themeManager.currentThemeColors.tabBarUnselected)
        
        // Configure appearance
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = backgroundColor
        
        // Set colors for normal and selected states
        appearance.stackedLayoutAppearance.normal.iconColor = unselectedColor
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: unselectedColor]
        
        appearance.stackedLayoutAppearance.selected.iconColor = selectedColor
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: selectedColor]
        
        // Apply appearance
        UITabBar.appearance().standardAppearance = appearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
        
        // Set tint color explicitly
        UITabBar.appearance().tintColor = selectedColor
    }
}
