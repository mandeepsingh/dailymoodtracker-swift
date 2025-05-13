//
//  ThemeStoreView.swift
//  DailyMoodTracker
//
//  Created by Mandeep Singh on 4/9/25.
//

import SwiftUI
import StoreKit

struct ThemeStoreView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var isLoading = false
    @State private var themeToConfirm: Theme? = nil
    @State private var showPurchaseConfirmation = false
    @State private var errorMessage: String = ""
    @State private var showError: Bool = false
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        // No NavigationView needed here - it's provided by parent
        List {
            ForEach(ThemeManager.allThemes) { theme in
                ThemeRow(
                    theme: theme,
                    isPurchased: !theme.isPremium || themeManager.purchasedThemes.contains(theme.id),
                    isActive: themeManager.currentTheme == theme.id,
                    price: formattedPrice(for: theme),
                    onPurchase: { purchaseTheme(theme) },
                    onActivate: { activateTheme(theme) }
                )
            }
        }
        .navigationTitle("Theme Store")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .bottomBar) {
                Button("Restore Purchases") {
                    restorePurchases()
                }
                .disabled(isLoading)
            }
            
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Back") {
                    presentationMode.wrappedValue.dismiss()
                }
            }
            
            #if DEBUG
            // Add to ThemeStoreView.swift, inside the toolbar section
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    themeManager.toggleDeveloperMode()
                }) {
                    Label(
                        themeManager.developerModeEnabled ? "Dev Mode: ON" : "Dev Mode: OFF",
                        systemImage: "hammer.fill"
                    )
                    .font(.caption)
                }
            }
            #endif
        }
        .overlay {
            if isLoading {
                ProgressView("Processing...")
                    .padding()
                    .background(Color.secondary.opacity(0.2))
                    .cornerRadius(10)
            }
        }
        .confirmationDialog(
            "Purchase \(themeToConfirm?.name ?? "Theme")",
            isPresented: $showPurchaseConfirmation,
            titleVisibility: .visible
        ) {
            Button("Purchase for \(themeToConfirm?.price ?? "$0.99")") {
                confirmPurchase()
            }
            
            Button("Cancel", role: .cancel) {
                themeToConfirm = nil
            }
        } message: {
            Text("Would you like to purchase this theme?")
        }
        // Use SwiftUI's onReceive instead of notification observers
        .onReceive(NotificationCenter.default.publisher(for: .productsLoaded)) { _ in
            isLoading = false
        }
        .onReceive(NotificationCenter.default.publisher(for: .purchaseCompleted)) { notification in
            isLoading = false
            if let themeId = notification.userInfo?["themeId"] as? String {
                themeManager.setCurrentTheme(themeId: themeId)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .purchaseFailed)) { notification in
            isLoading = false
            if let error = notification.userInfo?["error"] as? String {
                errorMessage = error
                showError = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .restoreCompleted)) { _ in
            isLoading = false
        }
        .onAppear {
            // Load products if not already loaded
            if themeManager.products.isEmpty {
                isLoading = true
                themeManager.setupStoreKit()
            }
        }
        .alert(isPresented: $showError) {
            Alert(
                title: Text("Error"),
                message: Text(errorMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        // Add theme background support
        .background(themeManager.currentThemeColors.background)
        .scrollContentBackground(.hidden) // iOS 16+ to hide default background
    }
    
    // Helper to get formatted price
    func formattedPrice(for theme: Theme) -> String {
        guard theme.isPremium else { return "Free" }
        
        if let product = themeManager.getProduct(for: theme.id) {
            return themeManager.formattedPrice(for: product)
        }
        
        return theme.price
    }
    
    func purchaseTheme(_ theme: Theme) {
        themeToConfirm = theme
        showPurchaseConfirmation = true
    }
    
    func confirmPurchase() {
        guard let theme = themeToConfirm else { return }
        
        isLoading = true
        themeManager.purchaseTheme(themeId: theme.id)
        themeToConfirm = nil
    }
    
    func activateTheme(_ theme: Theme) {
        themeManager.setCurrentTheme(themeId: theme.id)
    }
    
    func restorePurchases() {
        isLoading = true
        themeManager.restorePurchases()
    }
}

// Theme row in theme store - no changes needed
struct ThemeRow: View {
    let theme: Theme
    let isPurchased: Bool
    let isActive: Bool
    let price: String
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
                        Text(price)
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

struct Theme: Identifiable {
    let id: String
    let name: String
    let isPremium: Bool
    let price: String
    let colors: ThemeColors
    
    // Add an initializer to resolve the "extra argument" error
    init(id: String, name: String, isPremium: Bool, price: String, colors: ThemeColors) {
        self.id = id
        self.name = name
        self.isPremium = isPremium
        self.price = price
        self.colors = colors
    }
}
