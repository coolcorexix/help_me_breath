import SwiftUI
import Cocoa
import Foundation
import Combine

// View model to manage breathing dot state and interactions
class BreathingDotState: ObservableObject {
    @Published var isHovered = false
    let animationState = BreathingState()
}

class ViewBreathDotController: NSViewController {
    var circleWindow: NSWindow?
    private var windowManager: WindowManager?
    private var mouseTracker: Any?
    private let breathingDotState: BreathingDotState = BreathingDotState()
    
    // Dynamic circle size
    var dotSize: CGFloat = 50 {
        didSet {
            updateWindowSize()
        }
    }
    
    var isExpanded = false
    
    var breathingDotView: some View {
        BreathingDotView(state: breathingDotState, size: dotSize)
    }
    
    override func loadView() {
        self.view = NSHostingView(rootView: breathingDotView)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCircleWindow()
        setupMouseTracking()
    }
    
    deinit {
        if let tracker = mouseTracker {
            NSEvent.removeMonitor(tracker)
        }
        windowManager?.cleanup()
        windowManager = nil
    }
    
    func setupMouseTracking() {
        // Use a global mouse movement monitor instead of tracking area
        mouseTracker = NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) { [weak self] event in
            guard let self = self, let window = self.circleWindow else { return }
            
            // Convert mouse location to window coordinates
            let mouseLocation = NSEvent.mouseLocation
            let windowFrame = window.frame
            
            // Check if mouse is inside our window
            let isInside = NSPointInRect(mouseLocation, windowFrame)
            
            // Update hover state if needed
            if self.breathingDotState.isHovered != isInside {
                self.breathingDotState.isHovered = isInside
            }
        }
    }
    
    func setupCircleWindow() {
        // Make window size match the circle size
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: dotSize, height: dotSize),
            styleMask: [.borderless, .titled],
            backing: .buffered,
            defer: false
        )
        
        window.contentView = NSHostingView(rootView: breathingDotView)
        
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
        self.windowManager = WindowManager(window: window, owner: self, name: "BreathDot")
        
        // Then make it visible
        window.makeKeyAndOrderFront(nil)
        
        // Finally position it after it's fully initialized
        moveToBottomRight()
    }
    
    func moveToBottomRight() { 
        guard let screen = NSScreen.main, let window = circleWindow else { return }
        let screenRect = screen.frame
        let x = screenRect.maxX - dotSize - 25
        let y = screenRect.minY + 25
        window.setFrameOrigin(NSPoint(x: x, y: y))
    }
    
    // Update window size without recreating the view
    func updateWindowSize() {
        guard let window = circleWindow else { return }
        let newFrame = NSRect(
            x: window.frame.origin.x,
            y: window.frame.origin.y,
            width: dotSize,
            height: dotSize
        )
        window.setFrame(newFrame, display: true, animate: true)
    }
}

// Visual representation of the breathing dot
struct BreathingDotView: View {
    @ObservedObject var state: BreathingDotState
    let size: CGFloat
    
    var body: some View {
        ZStack {
            // Base circle
            Circle()
                .frame(width: size, height: size)
                .foregroundColor(.black)
            
            // Animated water level indicator
            WaterLevelView(breathingState: state.animationState)
                .frame(width: size, height: size)
                .clipShape(Circle())
        }
        .opacity(state.isHovered ? 1.0 : 0.7)
        .animation(.easeInOut(duration: 0.2), value: state.isHovered)
    }
}

// Water level animation component
struct WaterLevelView: View {
    @ObservedObject var breathingState: BreathingState
    
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
                    print("onAppear")
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
    private let breathingConfig: BreathingConfiguration
    private var phaseStartTime: Date?
    private var cancellables = Set<AnyCancellable>()
    
    enum BreathingPhase: Equatable {
        case inhale, inhaleHold, exhale, exhaleHold
    }
    
    init() {
        self.breathingConfig = BreathingConfiguration.shared
        setupConfigObserver()
    }
    
    private func setupConfigObserver() {
        breathingConfig.$currentMode
            .sink { [weak self] _ in
                self?.restartBreathingCycle()
            }
            .store(in: &cancellables)
    }
    
    private func restartBreathingCycle() {
        currentPhase = .inhale
        waterLevel = 0.2
        phaseStartTime = nil
        startBreathingCycle()
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
        
        let config = breathingConfig.currentPattern
        let elapsedTime = Date().timeIntervalSince(startTime)
        
        switch currentPhase {
        case .inhale:
            let progress = min(elapsedTime / config.inhaleSeconds, 1.0)
            waterLevel = 0.2 + (0.6 * CGFloat(progress))
            
            if progress >= 1.0 {
                currentPhase = config.inhaleHoldSeconds > 0 ? .inhaleHold : .exhale
                phaseStartTime = Date()
            }
            
        case .inhaleHold:
            if elapsedTime >= config.inhaleHoldSeconds {
                currentPhase = .exhale
                phaseStartTime = Date()
            }
            
        case .exhale:
            let progress = min(elapsedTime / config.exhaleSeconds, 1.0)
            waterLevel = 0.8 - (0.6 * CGFloat(progress))
            
            if progress >= 1.0 {
                currentPhase = config.exhaleHoldSeconds > 0 ? .exhaleHold : .inhale
                phaseStartTime = Date()
            }
            
        case .exhaleHold:
            if elapsedTime >= config.exhaleHoldSeconds {
                currentPhase = .inhale
                phaseStartTime = Date()
            }
        }
    }
    
    deinit {
        timer?.invalidate()
        cancellables.removeAll()
    }
} 