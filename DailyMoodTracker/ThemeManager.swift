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
    // Add this property to store products fetched from App Store
    private(set) var products: [SKProduct] = []
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
        
        // Fetch available products
        fetchAvailableProducts()
    }
    
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        DispatchQueue.main.async { [weak self] in
            self?.products = response.products
            
            // Log invalid product identifiers for debugging
            if !response.invalidProductIdentifiers.isEmpty {
                print("Invalid product identifiers: \(response.invalidProductIdentifiers)")
            }
            
            // Optional: Notify UI that products are available
            NotificationCenter.default.post(name: .productsLoaded, object: nil)
        }
    }
    
    func request(_ request: SKRequest, didFailWithError error: Error) {
        print("Product request failed: \(error.localizedDescription)")
        
        // Implement retry logic after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
            // Only retry if we still don't have products
            if let self = self, self.products.isEmpty {
                print("Retrying product request...")
                self.setupStoreKit()
            }
        }
    }
    
    func getProductID(for themeID: String) -> String? {
        return themeToProductIDMap[themeID]
    }
    
    // New method to get themeId from productId
    func getThemeID(from productID: String) -> String? {
        return themeToProductIDMap.first(where: { $0.value == productID })?.key
    }
    
    // Get product by theme ID
    func getProduct(for themeId: String) -> SKProduct? {
        guard let productID = getProductID(for: themeId) else {
            return nil
        }
        return products.first(where: { $0.productIdentifier == productID })
    }
    
    // Format price for display
    func formattedPrice(for product: SKProduct) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = product.priceLocale
        return formatter.string(from: product.price) ?? "\(product.price)"
    }
    
    func purchaseTheme(themeId: String) {
        guard let product = getProduct(for: themeId) else {
            // Notify about product not being available
            NotificationCenter.default.post(
                name: .purchaseFailed,
                object: nil,
                userInfo: ["error": "Product not available for purchase"]
            )
            return
        }
        
        // Check if purchase is allowed
        if !SKPaymentQueue.canMakePayments() {
            NotificationCenter.default.post(
                name: .purchaseFailed,
                object: nil,
                userInfo: ["error": "In-app purchases are not allowed on this device"]
            )
            return
        }
        
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
    }
    
    func restorePurchases() {
        if !SKPaymentQueue.canMakePayments() {
            NotificationCenter.default.post(
                name: .purchaseFailed,
                object: nil,
                userInfo: ["error": "In-app purchases are not allowed on this device"]
            )
            return
        }
        
        // Post notification that restore started
        NotificationCenter.default.post(name: .restoreStarted, object: nil)
        
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
    
    // Add this method for basic receipt validation
    func verifyReceipt() {
        // For production, you should implement server-side validation
        // This is a basic client-side validation for testing
        
        guard let receiptURL = Bundle.main.appStoreReceiptURL else {
            print("Receipt URL not found")
            return
        }
        
        guard let receiptData = try? Data(contentsOf: receiptURL) else {
            print("Receipt data could not be read")
            return
        }
        
        let receiptBase64 = receiptData.base64EncodedString()
        
        // In production, send receiptBase64 to your server for validation with Apple's servers
        print("Receipt validation should be performed server-side")
        
        #if DEBUG
        // For testing only - log receipt existence
        print("Receipt exists with length: \(receiptBase64.count)")
        #endif
    }
    func fetchAvailableProducts() {
        // Request product information
        let request = SKProductsRequest(productIdentifiers: Set(themeProductIDs))
        productsRequest = request
        request.delegate = self
        request.start()
    }
}

// Combined notification extensions
extension Notification.Name {
    static let productsLoaded = Notification.Name("ProductsLoaded")
    static let purchaseCompleted = Notification.Name("PurchaseCompleted")
    static let purchaseFailed = Notification.Name("PurchaseFailed")
    static let restoreStarted = Notification.Name("RestoreStarted")
    static let restoreCompleted = Notification.Name("RestoreCompleted")
}

// Extend to conform to SKPaymentTransactionObserver
extension ThemeManager: SKPaymentTransactionObserver {
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased:
                handlePurchasedTransaction(transaction)
                queue.finishTransaction(transaction)
                
            case .restored:
                handleRestoredTransaction(transaction)
                queue.finishTransaction(transaction)
                
            case .failed:
                handleFailedTransaction(transaction)
                queue.finishTransaction(transaction)
                
            case .deferred:
                // Payment deferred (e.g., awaiting parental approval)
                print("Payment deferred")
                
            case .purchasing:
                // Payment in process, no action needed
                break
                
            @unknown default:
                break
            }
        }
    }

    private func handlePurchasedTransaction(_ transaction: SKPaymentTransaction) {
        let productId = transaction.payment.productIdentifier
        
        // Verify receipt
        verifyReceipt()
        
        // Get theme ID from product ID
        guard let themeId = getThemeID(from: productId) else {
            print("Unknown product ID: \(productId)")
            return
        }
        
        // Update app state
        DispatchQueue.main.async { [weak self] in
            self?.addPurchasedTheme(themeId: themeId)
            
            // Post notification about successful purchase
            NotificationCenter.default.post(
                name: .purchaseCompleted,
                object: nil,
                userInfo: ["themeId": themeId]
            )
        }
    }

    private func handleRestoredTransaction(_ transaction: SKPaymentTransaction) {
        let productId = transaction.original?.payment.productIdentifier ?? ""
        
        // Get theme ID from product ID
        guard let themeId = getThemeID(from: productId) else {
            print("Unknown product ID: \(productId)")
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.addPurchasedTheme(themeId: themeId)
        }
    }

    private func handleFailedTransaction(_ transaction: SKPaymentTransaction) {
        if let error = transaction.error as? SKError {
            var errorMessage = "Transaction failed"
            
            // Provide more specific error messages based on error code
            switch error.code {
            case .paymentCancelled:
                // User cancelled - don't show an error
                return
                
            case .paymentInvalid:
                errorMessage = "Payment invalid"
                
            case .paymentNotAllowed:
                errorMessage = "Payments are not allowed on this device"
                
            case .storeProductNotAvailable:
                errorMessage = "This product is not available in your region"
                
            case .cloudServicePermissionDenied:
                errorMessage = "Access to cloud service was denied"
                
            case .cloudServiceNetworkConnectionFailed:
                errorMessage = "Network connection failed, please try again"
                
            default:
                errorMessage = error.localizedDescription
            }
            
            print("Transaction error: \(errorMessage)")
            
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: .purchaseFailed,
                    object: nil,
                    userInfo: ["error": errorMessage]
                )
            }
        }
    }
    
    // Handle restoration completion
    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        print("Restore completed")
        
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .restoreCompleted, object: nil)
        }
    }
    
    // Handle restoration failure
    func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        print("Restore failed: \(error.localizedDescription)")
        
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: .purchaseFailed,
                object: nil,
                userInfo: ["error": "Failed to restore purchases: \(error.localizedDescription)"]
            )
        }
    }
}
