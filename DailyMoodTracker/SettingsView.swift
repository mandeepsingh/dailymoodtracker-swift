import SwiftUI
import StoreKit

struct SettingsView: View {
    @AppStorage("currentTheme") private var currentTheme = "default"
    
    var body: some View {
        NavigationView {
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
                        // Implement export functionality
                    }
                    
                    Button("Clear All Data") {
                        // Show confirmation and implement clear data
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
                        if let url = URL(string: "https://yourapp.com/privacy") {
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
        }
    }
}
