//
//  ThemeColors.swift
//  DailyMoodTracker
//
//  Created by Mandeep Singh on 4/13/25.
//


// Add this to a new file called ThemeColors.swift
import SwiftUI

// Define theme colors structure
// Expanded ThemeColors structure
struct ThemeColors {
    let primary: Color       // Main color for buttons and interactive elements
    let background: Color    // App background
    let card: Color          // Card/content background
    let text: Color          // Primary text color
    let accent: Color        // Accent/highlight color
    let shadow: Color        // Shadow color for depth effects
    
    // Navigation bar colors
    let navBarBackground: Color  // Navigation bar background color
    let navBarText: Color        // Navigation bar title text color
    
    // Tab bar colors
    let tabBarBackground: Color  // Tab bar background
    let tabBarSelected: Color    // Selected tab item color
    let tabBarUnselected: Color  // Unselected tab item color
    
    // Default theme colors
    static let defaultLight = ThemeColors(
        primary: Color.purple,
        background: Color(UIColor.systemBackground),
        card: Color(UIColor.secondarySystemBackground),
        text: Color(UIColor.label),
        accent: Color.purple,
        shadow: Color.black.opacity(0.2),
        navBarBackground: Color.white,
        navBarText: Color.black,
        tabBarBackground: Color.white,
        tabBarSelected: Color.purple,
        tabBarUnselected: Color.gray
    )
    
    // Dark theme colors
    static let dark = ThemeColors(
        primary: Color.purple,
        background: Color(red: 0.1, green: 0.1, blue: 0.1),
        card: Color(red: 0.2, green: 0.2, blue: 0.2),
        text: Color.white,
        accent: Color.purple,
        shadow: Color.white.opacity(0.1),
        navBarBackground: Color(red: 0.15, green: 0.15, blue: 0.15),
        navBarText: Color.white,
        tabBarBackground: Color(red: 0.15, green: 0.15, blue: 0.15),
        tabBarSelected: Color.purple,
        tabBarUnselected: Color.gray
    )
    
    // Galaxy theme colors
    static let galaxy = ThemeColors(
        primary: Color(hex: "#2668c2"),
        background: Color(hex: "#313488"),
        card: Color(hex: "#419bc9").opacity(0.7),
        text: Color.white,
        accent: Color(hex: "#76ffd6"),
        shadow: Color.black.opacity(0.5),
        navBarBackground: Color(hex: "#2668c2"),
        navBarText: Color.white,
        tabBarBackground: Color(hex: "#2668c2"),
        tabBarSelected: Color(hex: "#76ffd6"),
        tabBarUnselected: Color(hex: "#5ccdd0").opacity(0.6)
    )
}

// Add this extension to use hex colors
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

