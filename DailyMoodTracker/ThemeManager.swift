import StoreKit
import Foundation
#if DEBUG
import SwiftUI
#endif

// Make ThemeManager inherit from NSObject
class ThemeManager: NSObject, ObservableObject, SKProductsRequestDelegate {
    
    #if DEBUG
    @Published var developerModeEnabled = false
    #endif
    
    static let shared = ThemeManager()
    let themeProductIDs = [
        "com.compileandcry.dailymoodtracker.darktheme",
        "com.compileandcry.dailymoodtracker.tidestheme",
        "com.compileandcry.dailymoodtracker.meadowtheme",
        "com.compileandcry.dailymoodtracker.sunlighttheme"
    ]
    let themeToProductIDMap: [String: String] = [
        "dark": "com.compileandcry.dailymoodtracker.darktheme",
        "tides": "com.compileandcry.dailymoodtracker.tidestheme",
        "meadow": "com.compileandcry.dailymoodtracker.meadowtheme",
        "sunlight": "com.compileandcry.dailymoodtracker.sunlighttheme"
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

    // URLs for receipt validation
    private let sandboxVerifyURL = "https://sandbox.itunes.apple.com/verifyReceipt"
    private let productionVerifyURL = "https://buy.itunes.apple.com/verifyReceipt"
    
    // Your app's shared secret for receipt validation
    private let appSharedSecret = "36f0fee96ec946f68c5ce3137138e38d" // Add your App Store Connect shared secret here
    
    private var productsRequest: SKProductsRequest?
    private var receiptRefreshRequest: SKReceiptRefreshRequest?
    // Add this property to store products fetched from App Store
    private(set) var products: [SKProduct] = []
    @Published var purchasedThemes: [String] = []
    @Published var currentTheme: String = "default"
    @Published var isLoading: Bool = false
    // Initialize with default theme colors directly
    @Published var currentThemeColors: ThemeColors = ThemeColors.defaultLight
    
    private let purchasedThemesKey = "purchasedThemes"
    private let currentThemeKey = "currentTheme"
    
    // Need to use override init() since we're inheriting from NSObject
    override init() {
        super.init()
        
        // Setup debug features for simulators
          #if DEBUG
          if isRunningInSimulator() {
              print("Running in simulator - StoreKit functionality may be limited")
          }
          #endif
        
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
    
    #if DEBUG
    func toggleDeveloperMode() {
        developerModeEnabled = !developerModeEnabled
        
        if developerModeEnabled {
            // In developer mode, unlock all themes
            let allThemeIds = ThemeManager.allThemes.compactMap { theme in
                return theme.isPremium ? theme.id : nil
            }
            addPurchasedThemes(themeIds: allThemeIds)
        } else {
            // When toggling off, restore to actual purchases
            if let savedThemes = UserDefaults.standard.stringArray(forKey: purchasedThemesKey) {
                purchasedThemes = savedThemes
            } else {
                purchasedThemes = ["default"]
            }
        }
        
        // Notify observers
        objectWillChange.send()
    }
    #endif
    
    private func isRunningInSimulator() -> Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
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
        
        if request is SKReceiptRefreshRequest {
            print("Receipt refresh failed: \(error.localizedDescription)")
            
            DispatchQueue.main.async {
                self.isLoading = false
                NotificationCenter.default.post(
                    name: .purchaseFailed,
                    object: nil,
                    userInfo: ["error": "Failed to refresh receipt: \(error.localizedDescription)"]
                )
            }
            return
        }
        
        // Implement retry logic after delay for product requests
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
            // Only retry if we still don't have products
            if let self = self, self.products.isEmpty {
                print("Retrying product request...")
                self.setupStoreKit()
            }
        }
    }
    
    func requestDidFinish(_ request: SKRequest) {
        if request is SKReceiptRefreshRequest {
            print("Receipt refresh completed")
            // Now that we have a fresh receipt, validate it
            verifyReceipt()
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
        
        // Set loading state
        isLoading = true
        
        // Post notification that restore started
        NotificationCenter.default.post(name: .restoreStarted, object: nil)
        
        // First, verify the receipt
        verifyReceipt()
        
        // Add a timeout in case the restore takes too long
        DispatchQueue.main.asyncAfter(deadline: .now() + 30.0) { [weak self] in
            if self?.isLoading == true {
                self?.isLoading = false
                NotificationCenter.default.post(
                    name: .purchaseFailed,
                    object: nil,
                    userInfo: ["error": "Restore timed out. Please try again."]
                )
            }
        }
    }
    
    func addPurchasedTheme(themeId: String) {
        if !purchasedThemes.contains(themeId) {
            purchasedThemes.append(themeId)
            saveThemes()
        }
    }
    
    // Add this method to add multiple purchased themes at once
    func addPurchasedThemes(themeIds: [String]) {
        var updated = false
        
        for themeId in themeIds {
            if !purchasedThemes.contains(themeId) {
                purchasedThemes.append(themeId)
                updated = true
            }
        }
        
        if updated {
            saveThemes()
            
            // Notify that themes were restored
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: .restoreCompleted,
                    object: nil,
                    userInfo: ["restoredThemes": themeIds]
                )
            }
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
    
    // Update the verifyReceipt method to validate with Apple's servers and extract purchases
    func verifyReceipt() {
            #if DEBUG
            // In simulator with developer mode, skip validation
            if isRunningInSimulator() && developerModeEnabled {
                print("Developer mode enabled in simulator - skipping receipt validation")
                DispatchQueue.main.async { [weak self] in
                    self?.isLoading = false
                    
                    // Notify about successful "restore"
                    let restoredThemes = self?.purchasedThemes ?? []
                    NotificationCenter.default.post(
                        name: .restoreCompleted,
                        object: nil,
                        userInfo: ["restoredCount": restoredThemes.count]
                    )
                }
                return
            }
            #endif
        
        guard let receiptURL = Bundle.main.appStoreReceiptURL else {
            print("Receipt URL not found")
            // Request a new receipt if none exists
            refreshReceipt()
            return
        }
        
        guard FileManager.default.fileExists(atPath: receiptURL.path) else {
            print("Receipt file doesn't exist")
            refreshReceipt()
            return
        }
        
        guard let receiptData = try? Data(contentsOf: receiptURL) else {
            print("Receipt data could not be read")
            refreshReceipt()
            return
        }
        
        let receiptBase64 = receiptData.base64EncodedString()
        
        // Create the request to Apple's servers
        validateReceiptWithApple(receiptBase64: receiptBase64, isProduction: true)
    }
    
    // Method to validate receipt with Apple's servers
    private func validateReceiptWithApple(receiptBase64: String, isProduction: Bool) {
        // Prepare the request
        let verifyURL = isProduction ? productionVerifyURL : sandboxVerifyURL
        guard let url = URL(string: verifyURL) else {
            print("Invalid verification URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Create the request body
        var requestBody: [String: Any] = [
            "receipt-data": receiptBase64,
            "exclude-old-transactions": false
        ]
        
        // Add shared secret if available
        if !appSharedSecret.isEmpty {
            requestBody["password"] = appSharedSecret
        }
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            print("Failed to create request body: \(error)")
            return
        }
        
        // Create the task
        let task = URLSession.shared.dataTask(with: request) { [weak self] (data, response, error) in
            // Handle network error
            if let error = error {
                print("Receipt validation network error: \(error)")
                DispatchQueue.main.async {
                    self?.isLoading = false
                    
                    // If production validation failed, try sandbox
                    if isProduction {
                        self?.validateReceiptWithApple(receiptBase64: receiptBase64, isProduction: false)
                        return
                    }
                    
                    // Both production and sandbox failed, fall back to StoreKit restore
                    SKPaymentQueue.default().restoreCompletedTransactions()
                }
                return
            }
            
            // Check HTTP response
            guard let httpResponse = response as? HTTPURLResponse else {
                print("Invalid HTTP response")
                DispatchQueue.main.async {
                    self?.isLoading = false
                    SKPaymentQueue.default().restoreCompletedTransactions()
                }
                return
            }
            
            // Check for successful status code
            guard httpResponse.statusCode == 200 else {
                print("HTTP error: \(httpResponse.statusCode)")
                
                // If production validation failed with non-200, try sandbox
                if isProduction {
                    DispatchQueue.main.async {
                        self?.validateReceiptWithApple(receiptBase64: receiptBase64, isProduction: false)
                    }
                    return
                }
                
                // Both production and sandbox failed, fall back to StoreKit restore
                DispatchQueue.main.async {
                    self?.isLoading = false
                    SKPaymentQueue.default().restoreCompletedTransactions()
                }
                return
            }
            
            // Parse response data
            guard let data = data,
                  let jsonResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let status = jsonResponse["status"] as? Int else {
                print("Invalid response data")
                DispatchQueue.main.async {
                    self?.isLoading = false
                    SKPaymentQueue.default().restoreCompletedTransactions()
                }
                return
            }
            
            // Check response status
            if status != 0 {
                print("Receipt validation error, status: \(status)")
                
                // Status 21007 means this is a sandbox receipt sent to production
                if status == 21007 && isProduction {
                    DispatchQueue.main.async {
                        self?.validateReceiptWithApple(receiptBase64: receiptBase64, isProduction: false)
                    }
                    return
                }
                
                // Other error, fall back to StoreKit restore
                DispatchQueue.main.async {
                    self?.isLoading = false
                    SKPaymentQueue.default().restoreCompletedTransactions()
                }
                return
            }
            
            // Process receipt information
            self?.processReceiptResponse(jsonResponse)
        }
        
        task.resume()
    }
    
    // Process Apple's receipt validation response
    private func processReceiptResponse(_ response: [String: Any]) {
        // Extract in-app purchases
        guard let receiptInfo = response["receipt"] as? [String: Any],
              let inAppPurchases = receiptInfo["in_app"] as? [[String: Any]] else {
            print("No in-app purchases found in receipt")
            DispatchQueue.main.async {
                self.isLoading = false
                SKPaymentQueue.default().restoreCompletedTransactions()
            }
            return
        }
        
        // Process all purchases from receipt
        var restoredThemeIds: [String] = []
        
        for purchase in inAppPurchases {
            guard let productId = purchase["product_id"] as? String else {
                continue
            }
            
            // Get the theme ID for this product
            if let themeId = getThemeID(from: productId) {
                restoredThemeIds.append(themeId)
            }
        }
        
        // Add all restored themes to purchased list
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Add the restored themes
            self.addPurchasedThemes(themeIds: restoredThemeIds)
            
            // Update UI state
            self.isLoading = false
            
            // Notify about restore completion
            let restoredCount = restoredThemeIds.count
            NotificationCenter.default.post(
                name: .restoreCompleted,
                object: nil,
                userInfo: [
                    "restoredCount": restoredCount,
                    "restoredThemes": restoredThemeIds
                ]
            )
            
            if restoredCount == 0 {
                // If we didn't find any purchases in the receipt, fall back to StoreKit
                SKPaymentQueue.default().restoreCompletedTransactions()
            }
        }
    }
    
    // Add this method to refresh the receipt if it's missing
    private func refreshReceipt() {
        let request = SKReceiptRefreshRequest(receiptProperties: nil)
        receiptRefreshRequest = request
        request.delegate = self
        request.start()
        print("Refreshing App Store receipt...")
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
            self?.isLoading = false
            self?.addPurchasedTheme(themeId: themeId)
            
            // Post notification about successful purchase
            NotificationCenter.default.post(
                name: .purchaseCompleted,
                object: nil,
                userInfo: ["themeId": themeId]
            )
        }
    }

    // Update the handleRestoredTransaction method to be more robust
    private func handleRestoredTransaction(_ transaction: SKPaymentTransaction) {
        let productId = transaction.original?.payment.productIdentifier ?? transaction.payment.productIdentifier
        
        // Get theme ID from product ID
        guard let themeId = getThemeID(from: productId) else {
            print("Unknown product ID during restore: \(productId)")
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.addPurchasedTheme(themeId: themeId)
            
            // Post notification that a theme was restored
            NotificationCenter.default.post(
                name: .purchaseCompleted,
                object: nil,
                userInfo: ["themeId": themeId, "restored": true]
            )
        }
    }

    private func handleFailedTransaction(_ transaction: SKPaymentTransaction) {
        if let error = transaction.error as? SKError {
            var errorMessage = "Transaction failed"
            
            // Provide more specific error messages based on error code
            switch error.code {
            case .paymentCancelled:
                // User cancelled - don't show an error
                DispatchQueue.main.async { [weak self] in
                    self?.isLoading = false
                }
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
            
            DispatchQueue.main.async { [weak self] in
                self?.isLoading = false
                NotificationCenter.default.post(
                    name: .purchaseFailed,
                    object: nil,
                    userInfo: ["error": errorMessage]
                )
            }
        }
    }
    
    // Enhance the paymentQueueRestoreCompletedTransactionsFinished method
    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        print("StoreKit restore completed")
        
        // Check if we actually restored any themes
        let restoredCount = purchasedThemes.count > 0 ? purchasedThemes.count - 1 : 0 // Subtract 1 for default theme
        
        DispatchQueue.main.async { [weak self] in
            self?.isLoading = false
            NotificationCenter.default.post(
                name: .restoreCompleted,
                object: nil,
                userInfo: ["restoredCount": restoredCount]
            )
        }
    }
    
    // Handle restoration failure
    func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        print("StoreKit restore failed: \(error.localizedDescription)")
        
        DispatchQueue.main.async { [weak self] in
            self?.isLoading = false
            NotificationCenter.default.post(
                name: .purchaseFailed,
                object: nil,
                userInfo: ["error": "Failed to restore purchases: \(error.localizedDescription)"]
            )
        }
    }
}
