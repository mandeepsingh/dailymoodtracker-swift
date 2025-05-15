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
    
    private var isSandboxEnvironment: Bool {
        #if DEBUG
        return true
        #else
        // Check for sandbox receipt
        if let receiptURL = Bundle.main.appStoreReceiptURL {
            return receiptURL.lastPathComponent == "sandboxReceipt"
        }
        return false
        #endif
    }
    static var debugThemes = false
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
        
        #if DEBUG
        if isRunningInSimulator() {
            print("Running in simulator - StoreKit functionality may be limited")
        }
        #endif
        
        purchasedThemes = ["default"]
        
        // Load saved additional purchased themes
        if let savedThemes = UserDefaults.standard.stringArray(forKey: purchasedThemesKey) {
            // Add saved themes but avoid duplicates
            for theme in savedThemes {
                if !purchasedThemes.contains(theme) {
                    purchasedThemes.append(theme)
                }
            }
        }
        
        // Get the saved current theme or use default
        if let savedTheme = UserDefaults.standard.string(forKey: currentThemeKey) {
            if purchasedThemes.contains(savedTheme) {
                currentTheme = savedTheme
            } else {
                currentTheme = "default"
                UserDefaults.standard.set("default", forKey: currentThemeKey)
            }
        } else {
            UserDefaults.standard.set("default", forKey: currentThemeKey)
        }
        
        updateThemeColors()
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
        // Debug output to help identify the issue
        print("Updating theme colors for: \(currentTheme)")
        
        if let theme = ThemeManager.allThemes.first(where: { $0.id == currentTheme }) {
            currentThemeColors = theme.colors
            print("Theme updated to: \(theme.name) (ID: \(theme.id))")
            
            // Print actual color values for debugging
            print("Background: \(theme.colors.background)")
            print("Card: \(theme.colors.card)")
            print("Text: \(theme.colors.text)")
        } else {
            print("WARNING: Could not find theme with ID: \(currentTheme)")
            print("Available themes: \(ThemeManager.allThemes.map { $0.id })")
            
            // Fallback to default - explicitly use defaultLight
            currentThemeColors = ThemeColors.defaultLight
            currentTheme = "default"
            
            // Save this to UserDefaults to ensure consistency
            UserDefaults.standard.set("default", forKey: currentThemeKey)
        }
        
        // Always notify observers when theme colors change
        objectWillChange.send()
    }
    
    func setupStoreKit() {
        // Set up transaction observer for StoreKit
        SKPaymentQueue.default().add(self)
        
        // Fetch available products
        fetchAvailableProducts()
        
        // Log status after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            StoreKitHelper.shared.logStoreKitStatus()
        }
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
    
    // ThemeManager.swift
    // Update the purchaseTheme method to add better logging for sandbox

    func purchaseTheme(themeId: String) {
        print("Attempting to purchase theme: \(themeId)")
        
        guard let product = getProduct(for: themeId) else {
            let errorMessage = "Product not available for purchase"
            print("Purchase error: \(errorMessage)")
            NotificationCenter.default.post(
                name: .purchaseFailed,
                object: nil,
                userInfo: ["error": errorMessage]
            )
            return
        }
        
        // Check if purchase is allowed
        if !SKPaymentQueue.canMakePayments() {
            let errorMessage = "In-app purchases are not allowed on this device"
            print("Purchase error: \(errorMessage)")
            NotificationCenter.default.post(
                name: .purchaseFailed,
                object: nil,
                userInfo: ["error": errorMessage]
            )
            return
        }
        
        print("Initiating payment for product: \(product.productIdentifier)")
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
        
        // In sandbox, payments should be approved quickly
        print("Payment added to queue. In sandbox, you'll need to confirm with a test account password.")
        
        // For testing only - add a timeout warning
        #if DEBUG
        DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
            print("⚠️ Payment taking longer than expected. In sandbox environment, make sure to respond to the App Store prompt.")
        }
        #endif
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
        if ThemeManager.debugThemes {
            print("Setting theme to: \(themeId)")
            print("Call stack: \(Thread.callStackSymbols.joined(separator: "\n"))")
        }
        
        currentTheme = themeId
        UserDefaults.standard.set(themeId, forKey: currentThemeKey)
        
        // Update theme colors
        updateThemeColors()
        
        // Post a notification that theme changed so observers can update UI
        NotificationCenter.default.post(name: .themeChanged, object: nil)
    }
    
    private func saveThemes() {
        // Always ensure default is included
        if !purchasedThemes.contains("default") {
            purchasedThemes.append("default")
        }
        
        UserDefaults.standard.set(purchasedThemes, forKey: purchasedThemesKey)
        
        // Debug output
        print("Saved purchased themes: \(purchasedThemes)")
    }
    
    // Update the verifyReceipt method to validate with Apple's servers and extract purchases
    func verifyReceipt() {
        // For App Store review, always check sandbox first
        let shouldStartWithSandbox = isSandboxEnvironment
        
        guard let receiptURL = Bundle.main.appStoreReceiptURL else {
            print("Receipt URL not found")
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
        
        // Start with sandbox for review builds or when we detect sandbox receipt
        validateReceiptWithApple(receiptBase64: receiptBase64, isProduction: !shouldStartWithSandbox)
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
        print("Fetching available products...")
        let request = SKProductsRequest(productIdentifiers: Set(themeProductIDs))
        productsRequest = request
        request.delegate = self
        request.start()
        
        // Set a timeout to retry if products aren't loaded
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) { [weak self] in
            guard let self = self else { return }
            if self.products.isEmpty {
                print("Products not loaded after timeout, retrying...")
                let newRequest = SKProductsRequest(productIdentifiers: Set(self.themeProductIDs))
                self.productsRequest = newRequest
                newRequest.delegate = self
                newRequest.start()
            }
        }
    }
    
    func printProductStatus() {
        print("--- Product Status ---")
        print("Products loaded: \(products.count)")
        for product in products {
            print("Product: \(product.productIdentifier), Title: \(product.localizedTitle)")
        }
        if products.isEmpty {
            print("WARNING: No products loaded!")
        }
        print("---------------------")
    }
}

// Combined notification extensions
extension Notification.Name {
    static let productsLoaded = Notification.Name("ProductsLoaded")
    static let purchaseCompleted = Notification.Name("PurchaseCompleted")
    static let purchaseFailed = Notification.Name("PurchaseFailed")
    static let restoreStarted = Notification.Name("RestoreStarted")
    static let restoreCompleted = Notification.Name("RestoreCompleted")
    static let themeChanged = Notification.Name("ThemeChanged")
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
