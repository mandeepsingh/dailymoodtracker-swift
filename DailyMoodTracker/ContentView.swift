// ContentView.swift - Main tab view
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        TabView {
            EntryView()
                .tabItem {
                    Label("New Entry", systemImage: "plus.circle")
                }
            
            HistoryView()
                .tabItem {
                    Label("History", systemImage: "list.bullet")
                }
            
            TrendsView()
                .tabItem {
                    Label("Trends", systemImage: "chart.line.uptrend.xyaxis")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .accentColor(themeManager.currentThemeColors.tabBarSelected) // Active tab color
        .onChange(of: themeManager.currentTheme) { _ in
            updateAppearance()
        }
        .onAppear {
            updateAppearance()
        }
    }
    
    private func updateAppearance() {
        DispatchQueue.main.async {
            // Create a new appearance object each time
            let tabBarAppearance = UITabBarAppearance()
            tabBarAppearance.configureWithOpaqueBackground()
            tabBarAppearance.backgroundColor = UIColor(themeManager.currentThemeColors.tabBarBackground)
            
            // Set the colors for the tab items
            tabBarAppearance.stackedLayoutAppearance.normal.iconColor = UIColor(themeManager.currentThemeColors.tabBarUnselected)
            tabBarAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [
                .foregroundColor: UIColor(themeManager.currentThemeColors.tabBarUnselected)
            ]
            
            tabBarAppearance.stackedLayoutAppearance.selected.iconColor = UIColor(themeManager.currentThemeColors.tabBarSelected)
            tabBarAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [
                .foregroundColor: UIColor(themeManager.currentThemeColors.tabBarSelected)
            ]
            
            // Apply to EVERY tab bar in the app
            UITabBar.appearance().standardAppearance = tabBarAppearance
            if #available(iOS 15.0, *) {
                UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
            }
            
            // Force update by setting the tint color directly
            UITabBar.appearance().tintColor = UIColor(themeManager.currentThemeColors.tabBarSelected)
            
            // Force layout refresh
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let tabBarController = windowScene.windows.first?.rootViewController as? UITabBarController {
                tabBarController.tabBar.setNeedsLayout()
            }
        }
    }
}
