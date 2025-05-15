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
        background: Color.white,
        card: Color.gray.opacity(0.2),
        text: Color.black,
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
    
    // Add to ThemeColors.swift
    static let sunlight = ThemeColors(
        primary: Color(hex: "#DD5E11"),      // Deep orange for primary actions
        background: Color(hex: "#E9EBED"),   // Light gray for background
        card: Color.white,                   // White for cards
        text: Color(hex: "#333333"),         // Dark gray for text
        accent: Color(hex: "#FFAB28"),       // Warm orange accent
        shadow: Color.black.opacity(0.1),    // Subtle shadows
        navBarBackground: Color(hex: "#FFDC78"), // Soft yellow for nav bar
        navBarText: Color(hex: "#DD5E11"),   // Deep orange nav text
        tabBarBackground: Color(hex: "#E9EBED"), // Light gray tab bar
        tabBarSelected: Color(hex: "#DD5E11"),   // Deep orange for selected tabs
        tabBarUnselected: Color.gray         // Gray for unselected tabs
    )
    
    static let tides = ThemeColors(
        primary: Color(hex: "#1ABBEF"),     // Medium blue for primary elements
        background: Color(hex: "#E9EBED"),  // Light gray/white for background
        card: Color.white,                  // White for cards
        text: Color(hex: "#006F98"),        // Dark blue for text
        accent: Color(hex: "#7FD2FD"),      // Light blue for accents
        shadow: Color.black.opacity(0.1),   // Light shadow
        navBarBackground: Color(hex: "#1ABBEF"), // Medium blue for navbar
        navBarText: Color.white,            // White text for navbar
        tabBarBackground: Color(hex: "#006F98"), // Dark blue for tab bar
        tabBarSelected: Color(hex: "#7FD2FD"),   // Light blue for selected tabs
        tabBarUnselected: Color.white.opacity(0.7) // White for unselected tabs
    )
    
    static let meadow = ThemeColors(
        primary: Color(hex: "#56B84D"),     // Medium green for primary elements
        background: Color(hex: "#E9EBED"),  // Light gray/white for background
        card: Color.white,                  // White for cards
        text: Color(hex: "#0F782E"),        // Dark green for text
        accent: Color(hex: "#FFDA81"),      // Light orange/gold for accents
        shadow: Color.black.opacity(0.1),   // Light shadow
        navBarBackground: Color(hex: "#56B84D"), // Medium green for navbar
        navBarText: Color.white,            // White text for navbar
        tabBarBackground: Color(hex: "#0F782E"), // Dark green for tab bar
        tabBarSelected: Color(hex: "#FFDA81"),   // Light orange/gold for selected tabs
        tabBarUnselected: Color.white.opacity(0.7) // White for unselected tabs
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
