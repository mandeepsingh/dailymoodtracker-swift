import StoreKit
import Foundation

// Make ThemeManager inherit from NSObject
class ThemeManager: NSObject, ObservableObject {
    static let shared = ThemeManager()
    
    @Published var purchasedThemes: [String] = []
    @Published var currentTheme: String = "default"
    
    private let purchasedThemesKey = "purchasedThemes"
    private let currentThemeKey = "currentTheme"
    
    // Need to use override init() since we're inheriting from NSObject
    override init() {
        // Initialize properties before super.init()
        super.init()
        
        // Load purchased themes from UserDefaults
        if let savedThemes = UserDefaults.standard.stringArray(forKey: purchasedThemesKey) {
            purchasedThemes = savedThemes
        }
        
        // Load current theme from UserDefaults
        if let savedTheme = UserDefaults.standard.string(forKey: currentThemeKey) {
            currentTheme = savedTheme
        }
        
        // Set up StoreKit transaction observer
        setupStoreKit()
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
