// ContentView.swift - Main tab view
import SwiftUI

struct ContentView: View {
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
        .accentColor(.purple)
    }
}
