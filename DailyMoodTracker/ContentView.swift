import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        TabView {
            NavigationView {
                EntryView()
            }
            .navigationViewStyle(StackNavigationViewStyle())
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
    }
    
    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(themeManager.currentThemeColors.tabBarBackground)
        
        // Configure normal and selected colors
        let normalColor = UIColor(themeManager.currentThemeColors.tabBarUnselected)
        let selectedColor = UIColor(themeManager.currentThemeColors.tabBarSelected)
        
        appearance.stackedLayoutAppearance.normal.iconColor = normalColor
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [NSAttributedString.Key.foregroundColor: normalColor]
        
        appearance.stackedLayoutAppearance.selected.iconColor = selectedColor
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [NSAttributedString.Key.foregroundColor: selectedColor]
        
        UITabBar.appearance().standardAppearance = appearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
        
        // Force the tab bar to have the right tint
        UITabBar.appearance().tintColor = selectedColor
    }
}
