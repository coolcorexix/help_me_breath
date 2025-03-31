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

// Main configuration class that will be shared across the app
class BreathingConfiguration: ObservableObject {
    // Current selected mode
    @Published var currentMode: BreathingMode = .casualWork
    
    // Patterns for each mode using predefined templates
    private let patterns: [BreathingMode: BreathingPattern] = [
        .casualWork: .casualWorkPattern,
        .deepFocus: .deepFocusPattern
    ]
    
    // Current pattern based on selected mode
    var currentPattern: BreathingPattern {
        patterns[currentMode] ?? .casualWorkPattern
    }
    
    // Convenience getters for current timings
    var inhaleTime: Double { currentPattern.inhaleSeconds }
    var inhaleHoldTime: Double { currentPattern.inhaleHoldSeconds }
    var exhaleTime: Double { currentPattern.exhaleSeconds }
    var exhaleHoldTime: Double { currentPattern.exhaleHoldSeconds }
    
    // Singleton instance for shared access
    static let shared = BreathingConfiguration()
    
    private init() {}
    
    // Method to switch breathing mode
    func switchMode(to mode: BreathingMode) {
        currentMode = mode
        print("Switched to \(mode.rawValue) mode:")
        print("- Inhale: \(inhaleTime)s")
        print("- Hold: \(inhaleHoldTime)s")
        print("- Exhale: \(exhaleTime)s")
        print("- Hold: \(exhaleHoldTime)s")
        print("Total cycle: \(currentPattern.totalCycleDuration)s")
    }
    
    // Method to get a description of the current pattern
    func getCurrentPatternDescription() -> String {
        """
        Mode: \(currentMode.rawValue)
        Inhale: \(inhaleTime)s
        Hold: \(inhaleHoldTime)s
        Exhale: \(exhaleTime)s
        Hold: \(exhaleHoldTime)s
        Total cycle: \(currentPattern.totalCycleDuration)s
        """
    }
}

// Extension to add custom patterns
extension BreathingConfiguration {
    // Method to create a custom pattern
    static func createCustomPattern(
        inhale: Double,
        inhaleHold: Double,
        exhale: Double,
        exhaleHold: Double
    ) -> BreathingPattern {
        BreathingPattern(
            inhaleSeconds: inhale,
            inhaleHoldSeconds: inhaleHold,
            exhaleSeconds: exhale,
            exhaleHoldSeconds: exhaleHold
        )
    }
    
    // Method to apply a predefined template
    func applyTemplate(_ mode: BreathingMode) {
        switchMode(to: mode)
    }
} 