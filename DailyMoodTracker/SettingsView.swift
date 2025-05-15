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
    @State private var showClearConfirmationSheet = false // Add this for iPad
    @State private var showingExportSuccess = false
    @State private var showingClearSuccess = false
    
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
                    #if targetEnvironment(macCatalyst) || os(iOS)
                    if UIDevice.current.userInterfaceIdiom == .pad {
                        // Use sheet for iPad
                        showClearConfirmationSheet = true
                    } else {
                        // Use dialog for iPhone
                        showingClearConfirmation = true
                    }
                    #else
                    showingClearConfirmation = true
                    #endif
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
                    if let url = URL(string: "http://daily-mood-tracker.com/mobile-privacy") {
                        UIApplication.shared.open(url)
                    }
                }

                Button("Terms of Use") {
                    if let url = URL(string: "http://daily-mood-tracker.com/mobile-terms") {
                        UIApplication.shared.open(url)
                    }
                }
                
                Button("Rate App") {
                    if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                        SKStoreReviewController.requestReview(in: scene)
                    }
                }
            }
        }
        .navigationTitle("Settings")
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(themeManager.currentThemeColors.accent, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
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
        .sheet(isPresented: $showClearConfirmationSheet) {
            DeleteConfirmationView(
                isPresented: $showClearConfirmationSheet,
                onConfirm: {
                    clearAllData()
                }
            )
            .environmentObject(themeManager)
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
        // Add theme-based styling for the list
        .listStyle(InsetGroupedListStyle())
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("OpenThemeStore"))) { _ in
            navigateToThemeStore()
        }
        .onAppear {
            updateNavigationBarAppearance()
        }
        .onChange(of: themeManager.currentTheme) { _ in
            updateNavigationBarAppearance()
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
    
    private func navigateToThemeStore() {
        // Directly present ThemeStoreView
        if let window = UIApplication.shared.windows.first,
           let rootViewController = window.rootViewController {
            let themeStoreView = ThemeStoreView()
                .environmentObject(themeManager)
            let hostingController = UIHostingController(rootView: themeStoreView)
            rootViewController.present(hostingController, animated: true)
        }
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

// Add the DeleteConfirmationView for iPad
struct DeleteConfirmationView: View {
    @Binding var isPresented: Bool
    var onConfirm: () -> Void
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Spacer()
                
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 70))
                    .foregroundColor(.red)
                    .padding(.bottom, 20)
                
                Text("Clear All Data")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("This will permanently delete all your mood entries.")
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                Text("This action cannot be undone.")
                    .fontWeight(.semibold)
                    .foregroundColor(.red)
                    .padding(.top, 10)
                
                Spacer()
                
                HStack(spacing: 30) {
                    Button(action: {
                        isPresented = false
                    }) {
                        Text("Cancel")
                            .frame(minWidth: 120)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(10)
                    }
                    
                    Button(action: {
                        onConfirm()
                        isPresented = false
                    }) {
                        Text("Delete All Data")
                            .frame(minWidth: 120)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                
                Spacer()
            }
            .padding()
            .frame(maxWidth: 500)
            .navigationTitle("Confirm Deletion")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Dismiss") {
                isPresented = false
            })
            .background(themeManager.currentThemeColors.background.edgesIgnoringSafeArea(.all))
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
