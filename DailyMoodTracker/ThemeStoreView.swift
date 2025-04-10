//
//  ThemeStoreView.swift
//  DailyMoodTracker
//
//  Created by Mandeep Singh on 4/9/25.
//


// ThemeStoreView.swift
import SwiftUI
import StoreKit

struct ThemeStoreView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var isLoading = false
    
    // Sample theme data
    let themes = [
        Theme(id: "default", name: "Default", isPremium: false, price: "Free"),
        Theme(id: "galaxy", name: "Galaxy", isPremium: true, price: "$2.99"),
        Theme(id: "ocean", name: "Ocean Blue", isPremium: true, price: "$2.99"),
        Theme(id: "forest", name: "Forest Green", isPremium: true, price: "$2.99"),
        Theme(id: "sunset", name: "Sunset Orange", isPremium: true, price: "$2.99")
    ]
    
    var body: some View {
        List {
            ForEach(themes) { theme in
                ThemeRow(
                    theme: theme,
                    isPurchased: !theme.isPremium || themeManager.purchasedThemes.contains(theme.id),
                    isActive: themeManager.currentTheme == theme.id,
                    onPurchase: { purchaseTheme(theme) },
                    onActivate: { activateTheme(theme) }
                )
            }
        }
        .navigationTitle("Theme Store")
        .toolbar {
            ToolbarItem(placement: .bottomBar) {
                Button("Restore Purchases") {
                    restorePurchases()
                }
                .disabled(isLoading)
            }
        }
        .overlay {
            if isLoading {
                ProgressView("Processing...")
                    .padding()
                    .background(Color.secondary.opacity(0.2))
                    .cornerRadius(10)
            }
        }
    }
    
    func purchaseTheme(_ theme: Theme) {
        isLoading = true
        
        // In a real app, use StoreKit API here
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            themeManager.addPurchasedTheme(themeId: theme.id)
            themeManager.setCurrentTheme(themeId: theme.id)
            isLoading = false
        }
    }
    
    func activateTheme(_ theme: Theme) {
        themeManager.setCurrentTheme(themeId: theme.id)
    }
    
    func restorePurchases() {
        isLoading = true
        
        // In a real app, this would call StoreKit's restore API
        themeManager.restorePurchases()
        
        // Simulate delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isLoading = false
        }
    }
}

// Theme row in theme store
struct ThemeRow: View {
    let theme: Theme
    let isPurchased: Bool
    let isActive: Bool
    let onPurchase: () -> Void
    let onActivate: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(theme.name)
                    .font(.headline)
                
                HStack {
                    if isActive {
                        Text("Active")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    
                    if isPurchased && !isActive {
                        Text("Purchased")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    
                    if theme.isPremium && !isPurchased {
                        Text(theme.price)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.purple)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
            }
            
            Spacer()
            
            if theme.isPremium && !isPurchased {
                Button("Purchase") {
                    onPurchase()
                }
                .buttonStyle(.bordered)
                .tint(.purple)
            } else if !isActive {
                Button("Apply") {
                    onActivate()
                }
                .buttonStyle(.bordered)
                .tint(.blue)
            }
        }
        .padding(.vertical, 4)
    }
}

// Theme model
struct Theme: Identifiable {
    let id: String
    let name: String
    let isPremium: Bool
    let price: String
}
