import StoreKit
import Foundation

// Make ThemeManager inherit from NSObject
class ThemeManager: NSObject, ObservableObject {
    static let shared = ThemeManager()
    
    // Define themes first so they can be referenced for initialization
    static let allThemes: [Theme] = [
        Theme(
            id: "default",
            name: "Default",
            isPremium: false,
            price: "Free",
            colors: ThemeColors.defaultLight
        ),
        Theme(
            id: "dark",
            name: "Dark Mode",
            isPremium: true,
            price: "$0.99",
            colors: ThemeColors.dark
        ),
        Theme(
            id: "galaxy",
            name: "Galaxy",
            isPremium: true,
            price: "$2.99",
            colors: ThemeColors.galaxy
        )
    ]
    
    @Published var purchasedThemes: [String] = []
    @Published var currentTheme: String = "default"
    // Initialize with default theme colors directly
    @Published var currentThemeColors: ThemeColors = ThemeColors.defaultLight
    
    private let purchasedThemesKey = "purchasedThemes"
    private let currentThemeKey = "currentTheme"
    
    // Need to use override init() since we're inheriting from NSObject
    override init() {
        super.init()
        
        // Load saved data after initialization
        if let savedThemes = UserDefaults.standard.stringArray(forKey: purchasedThemesKey) {
            purchasedThemes = savedThemes
        }
        
        if let savedTheme = UserDefaults.standard.string(forKey: currentThemeKey) {
            currentTheme = savedTheme
            // Update theme colors based on saved theme
            updateThemeColors()
        }
        
        setupStoreKit()
    }
    
    
    // New method to update theme colors based on currentTheme
    private func updateThemeColors() {
        if let theme = ThemeManager.allThemes.first(where: { $0.id == currentTheme }) {
            currentThemeColors = theme.colors
        }
    }
    
    func setupStoreKit() {
        // Set up transaction observer for StoreKit
        SKPaymentQueue.default().add(self)
    }
    
    func purchaseTheme(productId: String) {
        // Implement StoreKit purchase flow
        
        // For demo purposes:
        addPurchasedTheme(themeId: productId)
    }
    
    func restorePurchases() {
        // Implement StoreKit restore purchases
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
    
    func addPurchasedTheme(themeId: String) {
        if !purchasedThemes.contains(themeId) {
            purchasedThemes.append(themeId)
            saveThemes()
        }
    }
    
    func setCurrentTheme(themeId: String) {
          currentTheme = themeId
          UserDefaults.standard.set(themeId, forKey: currentThemeKey)
          
          // Update theme colors
          updateThemeColors()
      }
    
    private func saveThemes() {
        UserDefaults.standard.set(purchasedThemes, forKey: purchasedThemesKey)
    }
}

// Extend to conform to SKPaymentTransactionObserver
extension ThemeManager: SKPaymentTransactionObserver {
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased:
                // Handle successful purchase
                if let productId = transaction.payment.productIdentifier.components(separatedBy: ".").last {
                    addPurchasedTheme(themeId: productId)
                }
                queue.finishTransaction(transaction)
                
            case .restored:
                // Handle restoration
                if let productId = transaction.original?.payment.productIdentifier.components(separatedBy: ".").last {
                    addPurchasedTheme(themeId: productId)
                }
                queue.finishTransaction(transaction)
                
            case .failed:
                // Handle failure
                print("Transaction failed: \(transaction.error?.localizedDescription ?? "")")
                queue.finishTransaction(transaction)
                
            case .deferred, .purchasing:
                // Do nothing while waiting
                break
                
            @unknown default:
                break
            }
        }
    }
}
