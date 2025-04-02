import Foundation

// Enum to represent different breathing modes
public enum BreathingMode: String, CaseIterable {
    case casualWork = "Casual Work"
    case deepFocus = "Deep Focus"
}

// Struct to hold timing configuration for a breathing pattern
public struct BreathingPattern {
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

public class BreathingConfiguration: ObservableObject {
    @Published public var currentMode: BreathingMode = .casualWork
    
    private var patterns: [BreathingMode: BreathingPattern] = [
        .casualWork: .casualWorkPattern,
        .deepFocus: .deepFocusPattern
    ]
    
    public var currentPattern: BreathingPattern {
        patterns[currentMode] ?? .casualWorkPattern
    }
    
    public static let shared = BreathingConfiguration()
    
    private init() {}
    
    public func switchMode(to mode: BreathingMode) {
        currentMode = mode
    }
}

// Extension to add custom patterns
extension BreathingConfiguration {
    // Method to create a custom pattern
    public static func createCustomPattern(
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
    public func applyTemplate(_ mode: BreathingMode) {
        switchMode(to: mode)
    }
} 
