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
        print("Initializing DailyMoodTrackerApp...")
        
        // First, ensure ThemeManager is fully initialized
        _ = ThemeManager.shared
        
        // Then access saved theme
        let savedTheme = UserDefaults.standard.string(forKey: "currentTheme") ?? "default"
        print("Startup theme from UserDefaults: \(savedTheme)")
        
        #if DEBUG
        print("DEBUG build: Ensuring default theme on startup")
        ThemeManager.shared.setCurrentTheme(themeId: "default")
        #else
        // For production/TestFlight, respect saved theme but ensure it's valid
        if ThemeManager.allThemes.contains(where: { $0.id == savedTheme }) {
            ThemeManager.shared.setCurrentTheme(themeId: savedTheme)
        } else {
            ThemeManager.shared.setCurrentTheme(themeId: "default")
        }
        #endif
        
        // Add explicit product fetch
        ThemeManager.shared.fetchAvailableProducts()
        
        // Add delay to print product status for debugging
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            ThemeManager.shared.printProductStatus()
        }
        
        // Configure navigation bar appearance with theme colors
        updateNavigationAppearance()
        
        // Configure tab bar appearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor(ThemeManager.shared.currentThemeColors.tabBarBackground)
        
        // Set colors for normal and selected states
        let unselectedColor = UIColor(ThemeManager.shared.currentThemeColors.tabBarUnselected)
        let selectedColor = UIColor(ThemeManager.shared.currentThemeColors.tabBarSelected)
        
        tabBarAppearance.stackedLayoutAppearance.normal.iconColor = unselectedColor
        tabBarAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: unselectedColor]
        
        tabBarAppearance.stackedLayoutAppearance.selected.iconColor = selectedColor
        tabBarAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: selectedColor]
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().tintColor = selectedColor
        
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        }
        
        print("App Store Review Environment Check:")
        print("Bundle ID: \(Bundle.main.bundleIdentifier ?? "unknown")")
        print("App Version: \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown")")
        print("Build: \(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown")")

        // Add environment detection
        StoreKitHelper.shared.detectEnvironment()
        
        // Optional: Check if user is on a jailbroken device
        #if !DEBUG
        performJailbreakCheck()
        #endif
    }

    // Add this helper method
    private func updateNavigationAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        
        // Apply theme colors if available
        appearance.backgroundColor = UIColor(ThemeManager.shared.currentThemeColors.navBarBackground)
        appearance.titleTextAttributes = [.foregroundColor: UIColor(ThemeManager.shared.currentThemeColors.navBarText)]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
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
                updateTabBarAppearance()
                updateNavigationBarAppearance()
            }
            .onChange(of: themeManager.currentTheme) { _ in
                updateTabBarAppearance()
                updateNavigationBarAppearance()
            }
        } else {
            // Regular iPhone layout - keep using your original ContentView
            ContentView()
        }
    }
    
    private func updateNavigationBarAppearance() {
          let appearance = UINavigationBarAppearance()
          appearance.configureWithOpaqueBackground()
          appearance.backgroundColor = UIColor(themeManager.currentThemeColors.navBarBackground)
          appearance.titleTextAttributes = [.foregroundColor: UIColor(themeManager.currentThemeColors.navBarText)]
          
          UINavigationBar.appearance().standardAppearance = appearance
          UINavigationBar.appearance().scrollEdgeAppearance = appearance
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
