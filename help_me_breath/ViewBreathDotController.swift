import SwiftUI
import Cocoa
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

class ViewBreathDotController: NSViewController {
    var circleWindow: NSWindow?
    var mouseMonitor: Any?
    var isHovered = false {
        didSet {
            if oldValue != isHovered {
                print("Hover state changed to: \(isHovered)")
                updateView()
            }
        }
    }
    
    // Dynamic circle size
    var circleSize: CGFloat = 50 {
        didSet {
            updateWindowSize()
        }
    }
    
    var isExpanded = false
    
    var breathDotView: some View {
        ZStack {
            // Base circle
            Circle()
                .frame(width: circleSize, height: circleSize)
                .foregroundColor(.black)
            
            // Water animation
            WaterLevelView()
                .frame(width: circleSize, height: circleSize)
                .clipShape(Circle())
        }
        .opacity(isHovered ? 1.0 : 0.7)
    }
    
    override func loadView() {
        self.view = NSHostingView(rootView: breathDotView)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCircleWindow()
        setupMouseMonitoring()
    }
    
    deinit {
        if let monitor = mouseMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
    
    func setupMouseMonitoring() {
        // Use a global mouse movement monitor instead of tracking area
        mouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) { [weak self] event in
            guard let self = self, let window = self.circleWindow else { return }
            
            // Convert mouse location to window coordinates
            let mouseLocation = NSEvent.mouseLocation
            let windowFrame = window.frame
            
            // Check if mouse is inside our window
            let isInside = NSPointInRect(mouseLocation, windowFrame)
            
            // Update hover state if needed
            if self.isHovered != isInside {
                self.isHovered = isInside
            }
        }
    }
    
    // Update the view with current hover state
    private func updateView() {
        // Force refresh by recreating the SwiftUI view
        DispatchQueue.main.async {
            let newView = NSHostingView(rootView: self.breathDotView)
            
            // Update both the view controller's view and the window content view
            self.view = newView
            self.circleWindow?.contentView = newView
        }
    }
    
    func setupCircleWindow() {
        // Make window size match the circle size
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: circleSize, height: circleSize),
            styleMask: [.borderless], // Keep it truly borderless
            backing: .buffered,
            defer: false
        )
        
        window.backgroundColor = NSColor.clear
        window.isOpaque = false
        window.hasShadow = false
        window.level = NSWindow.Level.floating
        window.contentView = NSHostingView(rootView: breathDotView)
        
        // Make the window movable by dragging anywhere on it
        window.isMovableByWindowBackground = true
        
        // Register for key events to handle Cmd+W
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            // Handle Cmd+W for closing
            if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers == "w" {
                self?.circleWindow?.close()
                return nil as NSEvent? // consume the event
            }
            return event
        }
        
        // First assign the window
        self.circleWindow = window
        
        // Then make it visible
        window.makeKeyAndOrderFront(nil)
        
        // Finally position it after it's fully initialized
        moveToBottomRight()
    }
    
    func moveToBottomRight() { 
        guard let screen = NSScreen.main, let window = circleWindow else { return }
        let screenRect = screen.frame
        let x = screenRect.maxX - circleSize - 25
        let y = screenRect.minY + 25
        window.setFrameOrigin(NSPoint(x: x, y: y))
    }
    
    func updateWindowSize() {
        guard let window = circleWindow else { return }
        let newFrame = NSRect(
            x: window.frame.origin.x,
            y: window.frame.origin.y,
            width: circleSize,
            height: circleSize
        )
        window.setFrame(newFrame, display: true, animate: true)
        updateView()
    }
}

// Simple water level animation view
struct WaterLevelView: View {
    @StateObject private var breathingState = BreathingState()
    @StateObject private var breathingConfig = BreathingConfiguration.shared
    
    var waterColor: Color {
        switch breathingState.currentPhase {
        case .inhale, .inhaleHold:
            return .green
        case .exhale, .exhaleHold:
            return .white
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            Rectangle()
                .fill(waterColor)
                .frame(width: geometry.size.width, height: geometry.size.height * breathingState.waterLevel)
                .animation(.easeInOut(duration: 0.5), value: breathingState.waterLevel)
                .onAppear {
                    breathingState.startBreathingCycle()
                }
        }
    }
}

// Breathing state to manage the animation
class BreathingState: ObservableObject {
    @Published var waterLevel: CGFloat = 0.2
    @Published var currentPhase: BreathingPhase = .inhale
    private var timer: Timer?
    private var phaseStartTime: Date?
    private let breathingConfig = BreathingConfiguration.shared
    
    enum BreathingPhase: Equatable {
        case inhale, inhaleHold, exhale, exhaleHold
    }
    
    func startBreathingCycle() {
        timer?.invalidate()
        phaseStartTime = Date()
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            self?.updateBreathing()
        }
    }
    
    private func updateBreathing() {
        guard let startTime = phaseStartTime else {
            phaseStartTime = Date()
            return
        }
        
        let pattern = breathingConfig.currentPattern
        let elapsedTime = Date().timeIntervalSince(startTime)
        
        switch currentPhase {
        case .inhale:
            let progress = min(elapsedTime / pattern.inhaleSeconds, 1.0)
            waterLevel = 0.2 + (0.6 * progress) // Scale from 0.2 to 0.8
            
            if progress >= 1.0 {
                currentPhase = pattern.inhaleHoldSeconds > 0 ? .inhaleHold : .exhale
                phaseStartTime = Date()
            }
            
        case .inhaleHold:
            if elapsedTime >= pattern.inhaleHoldSeconds {
                currentPhase = .exhale
                phaseStartTime = Date()
            }
            
        case .exhale:
            let progress = min(elapsedTime / pattern.exhaleSeconds, 1.0)
            waterLevel = 0.8 - (0.6 * progress) // Scale from 0.8 to 0.2
            
            if progress >= 1.0 {
                currentPhase = pattern.exhaleHoldSeconds > 0 ? .exhaleHold : .inhale
                phaseStartTime = Date()
            }
            
        case .exhaleHold:
            if elapsedTime >= pattern.exhaleHoldSeconds {
                currentPhase = .inhale
                phaseStartTime = Date()
            }
        }
    }
    
    deinit {
        timer?.invalidate()
    }
} 