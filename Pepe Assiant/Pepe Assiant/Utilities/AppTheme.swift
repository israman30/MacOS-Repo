//
//  AppTheme.swift
//  Pepe Assiant
//
//  Friendly, vibrant theme for NeatOS
//

import SwiftUI
import AppKit

// MARK: - App Theme
enum AppTheme {
    // Primary palette - Fresh teal (organized, trustworthy)
    static let primary = Color(red: 0.18, green: 0.83, blue: 0.75)
    static let primaryDark = Color(red: 0.14, green: 0.65, blue: 0.58)
    static let primaryLight = Color(red: 0.65, green: 0.95, blue: 0.90)
    
    // Accent - Warm coral (energy, friendliness)
    static let accent = Color(red: 0.98, green: 0.58, blue: 0.35)
    static let accentSoft = Color(red: 0.99, green: 0.75, blue: 0.55)
    
    // Neutrals - Adaptive to light/dark mode for proper contrast
    static let surface = Color(NSColor.windowBackgroundColor)
    static let surfaceElevated = Color(NSColor.controlBackgroundColor)
    static let cardBackground = Color(NSColor.controlBackgroundColor)
    static let border = Color(NSColor.separatorColor)
    static let borderLight = Color(NSColor.quaternaryLabelColor)
    
    // Semantic
    static let success = Color(red: 0.22, green: 0.78, blue: 0.55)
    static let warning = Color(red: 0.98, green: 0.76, blue: 0.25)
    static let error = Color(red: 0.94, green: 0.35, blue: 0.35)
    
    // Gradients - blend primary tint with adaptive background
    static let headerGradient = LinearGradient(
        colors: [
            primary.opacity(0.2),
            Color(NSColor.controlBackgroundColor)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let userBubbleGradient = LinearGradient(
        colors: [primary, primaryDark],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let sendButtonGradient = LinearGradient(
        colors: [primary, primaryDark],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // Chip accent colors (varied for personality)
    static let chipColors: [Color] = [
        primary,
        accent,
        Color(red: 0.45, green: 0.55, blue: 0.95),  // Soft blue
        Color(red: 0.65, green: 0.45, blue: 0.85),  // Soft purple
    ]
}
