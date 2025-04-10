
import SwiftUI
import CoreData

struct EntryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedMood: Int = 2 // Default to Neutral (middle option)
    @State private var note: String = ""
    @State private var showAlert = false
    
    // Simplified moods: Sad (1), Neutral (2), Happy (3)
    let moodEmojis = ["😢", "😐", "😊"]
    let moodLabels = ["Sad", "Neutral", "Happy"]
    
    var body: some View {
        NavigationView {
            VStack {
                Text("How are you feeling today?")
                    .font(.title)
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
                                    .background(selectedMood == value ? Color.purple : Color.gray.opacity(0.2))
                                    .clipShape(Circle())
                                
                                Text(moodLabels[value-1])
                                    .font(.caption)
                                    .padding(.top, 4)
                            }
                        }
                    }
                    
                    Spacer()
                }
                .padding(.horizontal)
                
                // Rest of the view remains the same
                Text("Notes (optional):")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top)
                
                TextEditor(text: $note)
                    .frame(height: 150)
                    .padding()
                    .background(Color.gray.opacity(0.1))
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
                        .background(Color.purple)
                        .cornerRadius(10)
                        .padding()
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("New Entry")
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Success"),
                    message: Text("Your mood has been recorded!"),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
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
