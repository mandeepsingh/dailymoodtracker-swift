import SwiftUI
import CoreData

struct EntryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var selectedMood: Int = 2 // Default to Neutral (middle option)
    @State private var note: String = ""
    @State private var showAlert = false
    @State private var showingThemeStore = false
    
    // Simplified moods: Sad (1), Neutral (2), Happy (3)
    let moodEmojis = ["😢", "😐", "😊"]
    let moodLabels = ["Sad", "Neutral", "Happy"]
    
    var body: some View {
        // Removed the outer NavigationView since it's now provided in ModifiedContentView
        ZStack {
            // Background color from theme
            themeManager.currentThemeColors.background
            .ignoresSafeArea(.all) // Use .all instead of specific area
            .onAppear {
                print("EntryView appeared with background: \(themeManager.currentThemeColors.background)")
            }
            
            ScrollView {
                VStack {
                    Text("How are you feeling today?")
                        .font(.title)
                        .foregroundColor(themeManager.currentThemeColors.text)
                        .padding()
                    
                    HStack(spacing: 20) {
                        Spacer()
                        
                        ForEach(1...3, id: \.self) { value in
                            Button(action: {
                                selectedMood = value
                            }) {
                                VStack {
                                    Text(moodEmojis[value-1])
                                        .font(.system(size: 40))
                                        .frame(width: 80, height: 80)
                                        .background(selectedMood == value ?
                                                  themeManager.currentThemeColors.accent :
                                                    themeManager.currentThemeColors.card)
                                        .foregroundColor(themeManager.currentThemeColors.text)
                                        .clipShape(Circle())
                                    
                                    Text(moodLabels[value-1])
                                        .font(.caption)
                                        .foregroundColor(themeManager.currentThemeColors.text)
                                        .padding(.top, 4)
                                }
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    Text("Notes")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundColor(themeManager.currentThemeColors.text)
                        .padding(.horizontal)
                        .padding(.top)
                    

                    TextEditor(text: $note)
                        .frame(height: 150)
                        .scrollContentBackground(.hidden)
                        .foregroundColor(themeManager.currentThemeColors.text)
                        .padding()
                        .cornerRadius(8)
                        .padding(.horizontal)
                    
                    Button(action: {
                        saveMoodEntry()
                        showAlert = true
                    }) {
                        Text("Save Entry")
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(themeManager.currentThemeColors.primary)
                            .cornerRadius(10)
                            .padding()
                    }
                    Button(action: {
                        showingThemeStore = true
                    }) {
                        HStack {
                            Text("Theme Store")
                        }
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(themeManager.currentThemeColors.primary)
                        .cornerRadius(10)
                        .padding(.horizontal)
                        .padding(.top, 8)
                    }
                    .sheet(isPresented: $showingThemeStore) {
                        ThemeStoreView()
                            .environmentObject(themeManager)
                            .environment(\.managedObjectContext, viewContext)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .contentShape(Rectangle())  // Make the whole area tappable
               .onTapGesture {
                   hideKeyboard()
               }
        }
        .navigationTitle("New Entry")
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(themeManager.currentThemeColors.accent, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Success"),
                message: Text("Your mood has been recorded!"),
                dismissButton: .default(Text("OK"))
            )
        }
        // Removed .navigationViewStyle as it's now set in the parent view
    }
    
    func saveMoodEntry() {
        // Create a new MoodEntry using NSEntityDescription
        let newEntry = NSEntityDescription.insertNewObject(forEntityName: "MoodEntry", into: viewContext) as! NSManagedObject
        
        // Set the attributes
        newEntry.setValue(UUID().uuidString, forKey: "id")
        newEntry.setValue(Date(), forKey: "date")
        newEntry.setValue(Int16(selectedMood), forKey: "mood")
        if !note.isEmpty {
            newEntry.setValue(note, forKey: "note")
        }
        
        // Save the context
        do {
            try viewContext.save()
            note = ""
            selectedMood = 2 // Reset to Neutral
        } catch {
            print("Error saving entry: \(error)")
        }
    }
}

// Add this extension at the bottom of EntryView.swift file
#if canImport(UIKit)
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
#endif
