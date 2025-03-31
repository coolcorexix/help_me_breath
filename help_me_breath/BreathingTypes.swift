import Foundation

// Enum to represent different breathing modes
enum BreathingMode: String, CaseIterable {
    case casualWork = "Casual Work"
    case deepFocus = "Deep Focus"
}

// Struct to hold timing configuration for a breathing pattern
struct BreathingPattern {
    var inhaleSeconds: Double
    var inhaleHoldSeconds: Double
    var exhaleSeconds: Double
    var exhaleHoldSeconds: Double
    
    // Total duration of one complete breath cycle
    var totalCycleDuration: Double {
        inhaleSeconds + inhaleHoldSeconds + exhaleSeconds + exhaleHoldSeconds
    }
    
    // Predefined templates
    static let casualWorkPattern = BreathingPattern(
        inhaleSeconds: 5,
        inhaleHoldSeconds: 0,
        exhaleSeconds: 5,
        exhaleHoldSeconds: 0
    )
    
    static let deepFocusPattern = BreathingPattern(
        inhaleSeconds: 4,
        inhaleHoldSeconds: 4,
        exhaleSeconds: 4,
        exhaleHoldSeconds: 4
    )
} 