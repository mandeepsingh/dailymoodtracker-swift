// TrendsView.swift
import SwiftUI
import Charts // iOS 16+ only

struct TrendsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var themeManager: ThemeManager
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \MoodEntry.date, ascending: true)],
        predicate: NSPredicate(format: "date >= %@", Calendar.current.date(byAdding: .day, value: -7, to: Date())! as NSDate),
        animation: .default)
    private var recentEntries: FetchedResults<MoodEntry>
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \MoodEntry.date, ascending: true)],
        animation: .default)
    private var allEntries: FetchedResults<MoodEntry>
    
    let moodEmojis = ["😢", "😐", "😊"]
    let moodLabels = ["Sad", "Neutral", "Happy"]
    
    var body: some View {
        // Removed the outer NavigationView since it's provided by ModifiedContentView
        ZStack {
            // Background color
            themeManager.currentThemeColors.background
                .ignoresSafeArea()
            
            ScrollView {
                if allEntries.isEmpty {
                    VStack(spacing: 20) {
                        Text("No entries yet")
                            .font(.headline)
                            .foregroundColor(themeManager.currentThemeColors.text)
                            .padding(.top, 50)
                        
                        Text("Add your first mood entry in the New Entry tab")
                            .multilineTextAlignment(.center)
                            .foregroundColor(themeManager.currentThemeColors.text.opacity(0.7))
                            .padding(.horizontal)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 20) {
                        weeklyChartView
                        
                        statsSummaryView
                        
                        moodDistributionView
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Mood Trends")
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(themeManager.currentThemeColors.accent, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }
    
    // Weekly mood chart
    private var weeklyChartView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Last 7 Days")
                .font(.headline)
                .foregroundColor(themeManager.currentThemeColors.text)
            
            if #available(iOS 16.0, *) {
                if recentEntries.isEmpty {
                    Text("Add entries to see your weekly chart")
                        .foregroundColor(themeManager.currentThemeColors.text.opacity(0.7))
                        .frame(height: 220)
                } else {
                    Chart {
                        ForEach(recentEntries) { entry in
                            LineMark(
                                x: .value("Date", formatShortDate(entry.date ?? Date())),
                                y: .value("Mood", entry.mood)
                            )
                            .foregroundStyle(themeManager.currentThemeColors.accent)
                            
                            PointMark(
                                x: .value("Date", formatShortDate(entry.date ?? Date())),
                                y: .value("Mood", entry.mood)
                            )
                            .foregroundStyle(themeManager.currentThemeColors.accent)
                        }
                    }
                    .frame(height: 220)
                    .chartYScale(domain: 1...3)
                    .chartForegroundStyleScale([
                        "Mood": themeManager.currentThemeColors.accent
                    ])
                }
            } else {
                // Fallback for iOS 15 and earlier
                moodChartLegacyView
            }
        }
        .padding()
        .background(themeManager.currentThemeColors.card)
        .cornerRadius(12)
        .shadow(color: themeManager.currentThemeColors.shadow, radius: 3)
    }
    
    // Legacy chart view for iOS 15 and earlier
    private var moodChartLegacyView: some View {
        VStack(alignment: .leading, spacing: 10) {
            if recentEntries.isEmpty {
                Text("Add entries to see your weekly chart")
                    .foregroundColor(themeManager.currentThemeColors.text.opacity(0.7))
                    .frame(height: 200)
            } else {
                HStack(alignment: .bottom, spacing: 10) {
                    ForEach(recentEntries) { entry in
                        VStack {
                            // Calculate relative height (1-3 scale)
                            Rectangle()
                                .fill(themeManager.currentThemeColors.accent)
                                .frame(width: 30, height: CGFloat(entry.mood) * 50)
                            
                            Text(formatDay(entry.date ?? Date()))
                                .font(.caption)
                                .foregroundColor(themeManager.currentThemeColors.text)
                                .frame(width: 30)
                        }
                    }
                }
                .frame(height: 200)
                .padding(.top)
                
                // Y-axis labels
                HStack {
                    VStack(alignment: .leading) {
                        Text("3 - Happy")
                        Text("2 - Neutral")
                        Text("1 - Sad")
                    }
                    .font(.caption)
                    .foregroundColor(themeManager.currentThemeColors.text)
                    Spacer()
                }
            }
        }
    }
    
    // Stats summary view (average, entries count)
    private var statsSummaryView: some View {
        HStack {
            statsCard(title: "Average Mood", value: String(format: "%.1f", averageMood()))
            
            Spacer()
            
            statsCard(title: "Total Entries", value: "\(allEntries.count)")
        }
    }
    
    // Individual stat card
    private func statsCard(title: String, value: String) -> some View {
        VStack(alignment: .center, spacing: 5) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(themeManager.currentThemeColors.text.opacity(0.7))
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(themeManager.currentThemeColors.accent)
        }
        .frame(width: 150, height: 100)
        .background(themeManager.currentThemeColors.card)
        .cornerRadius(12)
        .shadow(color: themeManager.currentThemeColors.shadow.opacity(0.3), radius: 3)
    }
    
    // Mood distribution view (how many of each mood)
    private var moodDistributionView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Mood Distribution")
                .font(.headline)
                .foregroundColor(themeManager.currentThemeColors.text)
            
            ForEach(1...3, id: \.self) { moodValue in
                HStack {
                    Text(moodLabel(for: moodValue))
                        .frame(width: 100, alignment: .leading)
                        .foregroundColor(themeManager.currentThemeColors.text)
                    
                    // Bar representing count
                    GeometryReader { geometry in
                        let count = countForMood(moodValue)
                        let width = allEntries.isEmpty ? 0 :
                            CGFloat(count) / CGFloat(allEntries.count) * geometry.size.width
                        
                        RoundedRectangle(cornerRadius: 5)
                            .fill(themeManager.currentThemeColors.accent.opacity(0.7))
                            .frame(width: width)
                    }
                    .frame(height: 20)
                    
                    // Count
                    Text("\(countForMood(moodValue))")
                        .frame(width: 30, alignment: .trailing)
                        .foregroundColor(themeManager.currentThemeColors.text)
                }
            }
        }
        .padding()
        .background(themeManager.currentThemeColors.card)
        .cornerRadius(12)
        .shadow(color: themeManager.currentThemeColors.shadow.opacity(0.3), radius: 3)
    }
    
    // Helper functions remain the same
    func formatShortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return formatter.string(from: date)
    }
    
    func formatDay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }
    
    func moodLabel(for mood: Int) -> String {
        switch mood {
        case 1: return "Sad"
        case 2: return "Neutral"
        case 3: return "Happy"
        default: return ""
        }
    }
    
    func averageMood() -> Double {
        if allEntries.isEmpty {
            return 0
        }
        let sum = allEntries.reduce(0) { $0 + Int($1.mood) }
        return Double(sum) / Double(allEntries.count)
    }
    
    func countForMood(_ mood: Int) -> Int {
        return allEntries.filter { Int($0.mood) == mood }.count
    }
}
