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
    @State private var themeToConfirm: Theme? = nil
    @State private var showPurchaseConfirmation = false
    
    var body: some View {
        List {
            ForEach(ThemeManager.allThemes) { theme in
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
    }
    
    
    func purchaseTheme(_ theme: Theme) {
        themeToConfirm = theme
        showPurchaseConfirmation = true
    }
    
    func confirmPurchase() {
        guard let theme = themeToConfirm else { return }
        
        isLoading = true
        
        // In a real app, use StoreKit API here
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            themeManager.addPurchasedTheme(themeId: theme.id)
            themeManager.setCurrentTheme(themeId: theme.id)
            isLoading = false
            themeToConfirm = nil
        }
    }
    
    func activateTheme(_ theme: Theme) {
        themeManager.setCurrentTheme(themeId: theme.id)
    }
    
    func restorePurchases() {
        isLoading = true
        themeManager.restorePurchases()
        
        // Simulate delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isLoading = false
        }
    }
}

// Preview of the Galaxy theme
struct GalaxyThemePreview: View {
    let theme: Theme
    
    var body: some View {
        VStack(spacing: 10) {
            // Star field
            ZStack {
                // Background
                Rectangle()
                    .fill(theme.colors.background)
                    .frame(height: 100)
                
                // Stars
                ForEach(0..<20, id: \.self) { i in
                    Circle()
                        .fill(Color.white)
                        .frame(width: CGFloat.random(in: 1...3), height: CGFloat.random(in: 1...3))
                        .position(
                            x: CGFloat.random(in: 0...200),
                            y: CGFloat.random(in: 0...100)
                        )
                        .opacity(Double.random(in: 0.3...1.0))
                }
                
                // Galaxy swirl
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [theme.colors.accent.opacity(0.5), theme.colors.primary.opacity(0.1)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 70, height: 70)
                    .blur(radius: 15)
                    .offset(x: -20, y: 10)
            }
            .cornerRadius(8)
            
            // UI elements preview with Galaxy theme
            HStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(theme.colors.primary)
                    .frame(width: 60, height: 20)
                
                Spacer()
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(theme.colors.accent)
                    .frame(width: 40, height: 20)
            }
            .padding(.horizontal, 10)
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
