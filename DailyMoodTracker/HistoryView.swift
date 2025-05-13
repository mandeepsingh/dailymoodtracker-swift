import SwiftUI

struct HistoryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var themeManager: ThemeManager
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \MoodEntry.date, ascending: false)],
        animation: .default)
    private var entries: FetchedResults<MoodEntry>
    
    let moodEmojis = ["😢", "😐", "😊"]
    let moodLabels = ["Sad", "Neutral", "Happy"]
    
    var body: some View {
        // Removed outer NavigationView since it's provided in ModifiedContentView
        ZStack {
            // Background color
            themeManager.currentThemeColors.background
                .ignoresSafeArea()
            
            List {
                if entries.isEmpty {
                    Text("No entries yet. Create one from the New Entry tab!")
                        .foregroundColor(themeManager.currentThemeColors.text.opacity(0.7))
                        .padding()
                        .listRowBackground(themeManager.currentThemeColors.card)
                } else {
                    ForEach(entries) { entry in
                        VStack(alignment: .leading) {
                            HStack {
                                Text(formatDate(entry.date ?? Date()))
                                    .font(.headline)
                                    .foregroundColor(themeManager.currentThemeColors.text)
                                
                                Spacer()
                                
                                // Use entry.mood - 1 as the index to access the correct emoji
                                Text(moodEmojis[Int(entry.mood) - 1])
                                    .font(.title2)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(themeManager.currentThemeColors.accent.opacity(0.2))
                                    .foregroundColor(themeManager.currentThemeColors.text)
                                    .cornerRadius(10)
                            }
                            
                            if let note = entry.note, !note.isEmpty {
                                Text(note)
                                    .padding(.top, 5)
                                    .foregroundColor(themeManager.currentThemeColors.text.opacity(0.7))
                            }
                        }
                        .padding(.vertical, 5)
                        .listRowBackground(themeManager.currentThemeColors.card)
                    }
                    .onDelete(perform: deleteEntries)
                }
            }
            .listStyle(PlainListStyle()) // Use plain style for better theme control
            .scrollContentBackground(.hidden) // iOS 16+ to hide default background
        }
        .navigationTitle("History")
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(themeManager.currentThemeColors.accent, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        // Add toolbar with delete button if needed
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                EditButton()
                    .foregroundColor(.white)
            }
        }
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func deleteEntries(offsets: IndexSet) {
        withAnimation {
            offsets.map { entries[$0] }.forEach(viewContext.delete)
            try? viewContext.save()
        }
    }
}
