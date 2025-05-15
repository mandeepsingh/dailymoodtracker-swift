//
//  StoreKitHelper.swift
//  DailyMoodTracker
//
//  Created by Mandeep Singh on 5/13/25.
//


// StoreKitHelper.swift
import StoreKit
import Foundation

class StoreKitHelper {
    static let shared = StoreKitHelper()
    
    func detectEnvironment() {
        print("--- Environment Detection ---")
        
        // Check receipt URL for sandbox indication
        if let receiptURL = Bundle.main.appStoreReceiptURL {
            let isSandboxReceipt = receiptURL.lastPathComponent == "sandboxReceipt"
            print("Receipt path: \(receiptURL.path)")
            print("Appears to be sandbox receipt: \(isSandboxReceipt)")
            
            #if DEBUG
            print("Running in DEBUG mode - sandbox expected")
            #else
            if isSandboxReceipt {
                print("Running with SANDBOX receipt in RELEASE mode - correct for App Store review")
            } else {
                print("Running with PRODUCTION receipt in RELEASE mode")
            }
            #endif
        } else {
            print("No receipt URL found yet")
        }
        
        // Check StoreKit configuration
        print("StoreKit product IDs configured: \(ThemeManager.shared.themeProductIDs)")
        print("-------------------------")
    }

    // Also update the logStoreKitStatus method to call this
    func logStoreKitStatus() {
        detectEnvironment()
        
        print("--- StoreKit Status ---")
        // Rest of the method remains the same...
    }
}
