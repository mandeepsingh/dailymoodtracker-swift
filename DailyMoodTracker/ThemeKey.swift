//
//  ThemeKey.swift
//  DailyMoodTracker
//
//  Created by Mandeep Singh on 4/13/25.
//


// Create a new file: ThemeContext.swift
import SwiftUI

struct ThemeKey: EnvironmentKey {
    static let defaultValue: ThemeColors = ThemeManager.shared.currentThemeColors
}

extension EnvironmentValues {
    var themeColors: ThemeColors {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}
