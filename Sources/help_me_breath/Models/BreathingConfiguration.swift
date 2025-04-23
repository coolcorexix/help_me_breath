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
    @Published public var customPattern: BreathingPattern?
    
    private var patterns: [BreathingMode: BreathingPattern] = [
        .casualWork: .casualWorkPattern,
        .deepFocus: .deepFocusPattern
    ]
    
    public var currentPattern: BreathingPattern {
        if let custom = customPattern {
            return custom
        }
        return patterns[currentMode] ?? .casualWorkPattern
    }
    
    public static let shared = BreathingConfiguration()
    
    private init() {
        // Load saved custom pattern if exists
        if let savedPattern = loadSavedPattern() {
            customPattern = savedPattern
        }
    }

    public func updateCustomPattern(_ pattern: BreathingPattern) {
        customPattern = pattern
        // Save the pattern
        savePattern(pattern)
    }

    private func savePattern(_ pattern: BreathingPattern) {
        let patternData = [
            "inhaleSeconds": pattern.inhaleSeconds,
            "inhaleHoldSeconds": pattern.inhaleHoldSeconds,
            "exhaleSeconds": pattern.exhaleSeconds,
            "exhaleHoldSeconds": pattern.exhaleHoldSeconds
        ]
        UserDefaults.standard.set(patternData, forKey: "CustomBreathingPattern")
    }

    private func loadSavedPattern() -> BreathingPattern? {
        guard let patternData = UserDefaults.standard.dictionary(forKey: "CustomBreathingPattern") else {
            return nil
        }

        guard let inhaleSeconds = patternData["inhaleSeconds"] as? Double,
              let inhaleHoldSeconds = patternData["inhaleHoldSeconds"] as? Double,
              let exhaleSeconds = patternData["exhaleSeconds"] as? Double,
              let exhaleHoldSeconds = patternData["exhaleHoldSeconds"] as? Double else {
            return nil
        }

        return BreathingPattern(
            inhaleSeconds: inhaleSeconds,
            inhaleHoldSeconds: inhaleHoldSeconds,
            exhaleSeconds: exhaleSeconds,
            exhaleHoldSeconds: exhaleHoldSeconds
        )
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
        currentMode = mode
    }
} 
