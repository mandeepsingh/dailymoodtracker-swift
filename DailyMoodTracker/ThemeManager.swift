import StoreKit
import Foundation

// Make ThemeManager inherit from NSObject
class ThemeManager: NSObject, ObservableObject, SKProductsRequestDelegate {
    
    static let shared = ThemeManager()
    let themeProductIDs = [
        "com.compileandcry.dailymoodtracker.darktheme",
        "com.compileandcry.DailyMoodTracker.tidestheme",
        "com.compileandcry.DailyMoodTracker.meadowtheme",
        "com.compileandcry.DailyMoodTracker.sunlighttheme"
    ]
    let themeToProductIDMap: [String: String] = [
        "dark": "com.compileandcry.dailymoodtracker.darktheme",
        "tides": "com.compileandcry.DailyMoodTracker.tidestheme",
        "meadow": "com.compileandcry.DailyMoodTracker.meadowtheme",
        "sunlight": "com.compileandcry.DailyMoodTracker.sunlighttheme"
    ]
    
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
              id: "sunlight",
              name: "Sunlight",
              isPremium: true,
              price: "$1.99",
              colors: ThemeColors.sunlight
          ),
        Theme(
            id: "tides",
            name: "Tides",
            isPremium: true,
            price: "$1.99",
            colors: ThemeColors.tides
        ),
        Theme(
            id: "meadow",
            name: "Meadow",
            isPremium: true,
            price: "$1.99",
            colors: ThemeColors.meadow
        )
        
    ]

    private var productsRequest: SKProductsRequest?
    @Published var availableProducts: [SKProduct] = []
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
         
         // Request product information
         let request = SKProductsRequest(productIdentifiers: Set(themeProductIDs))
         productsRequest = request
         request.delegate = self // This should now work with the protocol conformance
         request.start()
     }
    
    // Implement the required SKProductsRequestDelegate methods
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        // Store the available products
        self.availableProducts = response.products
        
        // Log information about the products
        for product in response.products {
            print("Found product: \(product.productIdentifier) \(product.localizedTitle) \(product.price.floatValue)")
        }
        
        // Log any invalid product identifiers
        if !response.invalidProductIdentifiers.isEmpty {
            print("Invalid product identifiers: \(response.invalidProductIdentifiers)")
        }
    }
    
    func request(_ request: SKRequest, didFailWithError error: Error) {
        print("Product request failed: \(error.localizedDescription)")
    }
    
    func getProductID(for themeID: String) -> String? {
        return themeToProductIDMap[themeID]
    }
    
    func purchaseTheme(themeId: String) {
        guard let productID = getProductID(for: themeId),
              let product = availableProducts.first(where: { $0.productIdentifier == productID }) else {
            print("Product not found")
            return
        }
        
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
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
