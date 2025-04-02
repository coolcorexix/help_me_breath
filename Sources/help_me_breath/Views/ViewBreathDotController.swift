import SwiftUI
import Cocoa
import Foundation
import Combine

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