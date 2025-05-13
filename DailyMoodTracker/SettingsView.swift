// Add these imports at the top of your SettingsView.swift file
import SwiftUI
import StoreKit
import UniformTypeIdentifiers
import CoreData

struct SettingsView: View {
    @AppStorage("currentTheme") private var currentTheme = "default"
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var showingExportSheet = false
    @State private var exportedFileURL: URL?
    @State private var showingClearConfirmation = false
    @State private var showingExportSuccess = false
    @State private var showingClearSuccess = false
    @State private var showPrivacySheet = false
    @State private var showTermsSheet = false
    
    var body: some View {
        // Removed the outer NavigationView since it's provided in ModifiedContentView
        List {
            // Appearance section
            Section(header: Text("Appearance")) {
                NavigationLink(destination: ThemeStoreView()) {
                    Text("Theme Store")
                }
            }
            
            // Data management section
            Section {
                Button("Export Data") {
                    exportData()
                }
                
                Button("Clear All Data") {
                    showingClearConfirmation = true
                }
                .foregroundColor(.red)
            } header: {
                Text("Data")
            } footer: {
                Text("Clearing data will permanently remove all your mood entries.")
                    .font(.caption)
            }
            
            // App information section
            Section(header: Text("About")) {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.gray)
                }
                
                Button("Privacy Policy") {
                    showPrivacySheet = true
                }
                
                Button("Terms of Use") {
                    showTermsSheet = true
                }
                
                Button("Rate App") {
                    if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                        SKStoreReviewController.requestReview(in: scene)
                    }
                }
            }
        }
        .navigationTitle("Settings")
        .confirmationDialog(
            "Clear All Data",
            isPresented: $showingClearConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete All Data", role: .destructive) {
                clearAllData()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete all your mood entries. This action cannot be undone.")
        }
        .alert("Data Exported", isPresented: $showingExportSuccess) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your mood data has been successfully exported.")
        }
        .alert("Data Cleared", isPresented: $showingClearSuccess) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("All mood entries have been permanently deleted.")
        }
        .sheet(isPresented: $showingExportSheet) {
            if let fileURL = exportedFileURL {
                ActivityViewController(items: [fileURL], isPresented: $showingExportSheet)
            }
        }
        .sheet(isPresented: $showPrivacySheet) {
            PrivacyPolicyView()
        }
        .sheet(isPresented: $showTermsSheet) {
            TermsOfUseView()
        }
        // Add theme-based styling for the list
        .listStyle(InsetGroupedListStyle())
        .background(themeManager.currentThemeColors.background)
        .scrollContentBackground(.hidden) // iOS 16+ to hide default background
    }
    
    // Function to export all mood data to JSON
    private func exportData() {
        // Fetch all mood entries
        let fetchRequest = NSFetchRequest<MoodEntry>(entityName: "MoodEntry")
        
        do {
            let entries = try viewContext.fetch(fetchRequest)
            
            // Check if there are any entries to export
            if entries.isEmpty {
                // Show an alert that there's no data to export
                showingExportSuccess = true
                return
            }
            
            // Convert entries to dictionaries
            let entriesData = entries.compactMap { entry -> [String: Any]? in
                guard let id = entry.id, let date = entry.date else { return nil }
                
                var entryDict: [String: Any] = [
                    "id": id,
                    "date": date.timeIntervalSince1970,
                    "mood": entry.mood
                ]
                
                if let note = entry.note {
                    entryDict["note"] = note
                }
                
                return entryDict
            }
            
            // Create JSON data
            let jsonData = try JSONSerialization.data(withJSONObject: entriesData, options: .prettyPrinted)
            
            // Create file in documents directory
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let fileURL = documentsDirectory.appendingPathComponent("MoodData.json")
            
            // Write to file
            try jsonData.write(to: fileURL)
            
            // Set the file URL and show export sheet
            exportedFileURL = fileURL
            showingExportSheet = true
            
            print("File exported to: \(fileURL.path)")
            print("File exists: \(FileManager.default.fileExists(atPath: fileURL.path))")
            
        } catch {
            print("Error exporting data: \(error.localizedDescription)")
        }
    }
    
    // Function to clear all mood entries
    private func clearAllData() {
        // Get a reference to the persistent store coordinator
        let coordinator = viewContext.persistentStoreCoordinator
        
        // Fetch all entries with a fetch request
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "MoodEntry")
        
        // Create a batch delete request
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        // Configure the request to return the deleted object IDs
        batchDeleteRequest.resultType = .resultTypeObjectIDs
        
        do {
            // Execute the batch delete
            let batchDelete = try coordinator?.execute(batchDeleteRequest, with: viewContext) as? NSBatchDeleteResult
            
            // Get the deleted object IDs
            guard let deletedObjectIDs = batchDelete?.result as? [NSManagedObjectID] else { return }
            
            // Create a dictionary with the deleted objects
            let deletedObjects: [AnyHashable: Any] = [
                NSDeletedObjectsKey: deletedObjectIDs
            ]
            
            // Merge the changes into the view context
            NSManagedObjectContext.mergeChanges(fromRemoteContextSave: deletedObjects, into: [viewContext])
            
            // Save the context to ensure changes are persisted
            try viewContext.save()
            
            // Force refresh of any FetchRequests in the app
            NotificationCenter.default.post(name: NSNotification.Name.NSManagedObjectContextDidSave, object: viewContext)
            
            // Show success alert
            showingClearSuccess = true
        } catch {
            print("Error clearing data: \(error)")
        }
    }
}

// Keep the PrivacyPolicyView, TermsOfUseView, and ActivityViewController unchanged

struct PrivacyPolicyView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Privacy Policy")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Group {
                        Text("Last Updated: April 23, 2025")
                            .fontWeight(.semibold)
                        
                        Text("This Privacy Policy describes how your personal information is collected, used, and shared when you use the DailyMoodTracker app.")
                        
                        Text("Information We Collect")
                            .font(.headline)
                        
                        Text("DailyMoodTracker stores all user data locally on your device. We do not collect, store, or transmit your mood entries or personal information to our servers.")
                        
                        Text("In-App Purchases")
                            .font(.headline)
                        
                        Text("When you make an in-app purchase, the transaction is processed by Apple. We receive only anonymized information about purchases to validate them. Your payment information is never shared with us.")
                        
                        Text("Data Export")
                            .font(.headline)
                        
                        Text("Any data exported from the app is controlled by you and shared at your discretion. We do not have access to exported data files.")
                        
                        Text("Changes to this Policy")
                            .font(.headline)
                        
                        Text("We may update this privacy policy from time to time. We will notify you of any changes by posting the new privacy policy in the app.")
                        
                        Text("Contact Us")
                            .font(.headline)
                        
                        Text("If you have any questions about our privacy practices or this policy, please contact us at mandeep.wsu@gmail.com.")
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationBarTitle("Privacy Policy", displayMode: .inline)
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

struct TermsOfUseView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Terms of Use")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Group {
                        Text("Last Updated: April 23, 2025")
                            .fontWeight(.semibold)
                        
                        Text("By downloading or using the DailyMoodTracker app, you agree to be bound by these Terms of Use.")
                        
                        Text("App License")
                            .font(.headline)
                        
                        Text("DailyMoodTracker grants you a limited, non-transferable, non-exclusive license to use the Application on any iOS products that you own or control.")
                        
                        Text("In-App Purchases")
                            .font(.headline)
                        
                        Text("DailyMoodTracker offers premium themes via in-app purchases. All purchases are final and non-refundable, except as required by law. Premium content is linked to your Apple ID.")
                        
                        Text("User Data")
                            .font(.headline)
                        
                        Text("You retain all rights to your mood entries and personal data. We do not claim ownership of your content.")
                        
                        Text("Prohibited Uses")
                            .font(.headline)
                        
                        Text("You agree not to use the app for any illegal purpose or to violate any local, state, national, or international law.")
                        
                        Text("Termination")
                            .font(.headline)
                        
                        Text("We may terminate or suspend your access to the app immediately, without prior notice or liability, for any reason, including without limitation if you breach these Terms of Use.")
                        
                        Text("Changes to Terms")
                            .font(.headline)
                        
                        Text("We reserve the right to modify these terms at any time. We will provide notice of any significant changes.")
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationBarTitle("Terms of Use", displayMode: .inline)
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

struct ActivityViewController: UIViewControllerRepresentable {
    var items: [Any]
    @Binding var isPresented: Bool
    
    class Coordinator: NSObject, UIActivityItemSource, UINavigationControllerDelegate {
        let items: [Any]
        let parent: ActivityViewController
        
        init(items: [Any], parent: ActivityViewController) {
            self.items = items
            self.parent = parent
        }
        
        func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
            return items.first ?? ""
        }
        
        func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
            return items.first
        }
        
        func activityViewController(_ activityViewController: UIActivityViewController, dataTypeIdentifierForActivityType activityType: UIActivity.ActivityType?) -> String {
            return UTType.json.identifier
        }
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(items: items, parent: self)
    }
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        
        controller.completionWithItemsHandler = { (_, _, _, _) in
            DispatchQueue.main.async {
                self.isPresented = false
            }
        }
        
        // iPad support
        if let popover = controller.popoverPresentationController {
            popover.sourceView = UIViewController().view
        }
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
