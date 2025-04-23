import SwiftUI
import Cocoa

// State object to manage breathing state
class BreathingStateForBreathInput: ObservableObject {
    @Published var isInhaling = false
    @Published var inhalationStartTime: Date?
    @Published var exhalationStartTime: Date?
    @Published var columnHeight: CGFloat = 0
    @Published var isDecreasing = false
    @Published var isRecordingComplete = false
    @Published var saturation: Double = 0  // Add saturation state

    private var inhaleDurations: [TimeInterval] = [] {
        didSet {
            print("inhale durations: \(inhaleDurations)")
        }
    }
    private var exhaleDurations: [TimeInterval] = [] {
        didSet {
            print("exhale durations: \(exhaleDurations)")
        }
    }

    public var recordingCurrentIndex: Int = 0 {
        didSet {
            if recordingCurrentIndex >= 4 {
                isRecordingComplete = true
                updateBreathingPattern()
            }
            if !inhaleDurations.isEmpty {
                print("Recording current index: \(recordingCurrentIndex)")
            }
        }
    }

    private func calculateAverages() -> (inhale: Double, exhale: Double) {
        // Get last 3 durations
        let lastThreeInhales = Array(inhaleDurations.suffix(3))
        let lastThreeExhales = Array(exhaleDurations.suffix(3))
        
        // Calculate averages
        let avgInhale = lastThreeInhales.reduce(0.0, +) / Double(lastThreeInhales.count)
        let avgExhale = lastThreeExhales.reduce(0.0, +) / Double(lastThreeExhales.count)
        
        return (inhale: avgInhale, exhale: avgExhale)
    }
    
    // Add property to store the final averages
    private(set) var finalAverages: (inhale: Double, exhale: Double)?
    
    private func updateBreathingPattern() {
        let averages = calculateAverages()
        finalAverages = averages  // Store the final averages
        let newPattern = BreathingPattern(
            inhaleSeconds: averages.inhale,
            inhaleHoldSeconds: 0,  // Keeping hold times at 0 for now
            exhaleSeconds: averages.exhale,
            exhaleHoldSeconds: 0
        )
        
        // Update the breathing configuration
        BreathingConfiguration.shared.updateCustomPattern(newPattern)
        print("Updated breathing pattern - Inhale: \(averages.inhale)s, Exhale: \(averages.exhale)s")
    }

    func startInhaling() {
        isInhaling = true
        isDecreasing = false
        inhalationStartTime = Date()
        // Start with a small column height
        columnHeight = 50
        print("Started inhaling - Initial column height: \(columnHeight)")
    }
    
    func stopInhaling() {
        isInhaling = false
        isDecreasing = true
        if let startTime = inhalationStartTime {
            let duration = Date().timeIntervalSince(startTime)
            print("Stopped inhaling. Duration: \(String(format: "%.2f", duration)) seconds")
            print("Starting decrease from height: \(columnHeight)")
            inhaleDurations.append(duration)
        }
        inhalationStartTime = nil
    }

    func startExhaling() {
        isInhaling = false
        isDecreasing = true
        exhalationStartTime = Date()
        print("Started exhaling - Initial column height: \(columnHeight)")
    }

    func stopExhaling() {
        isInhaling = false
        isDecreasing = false
        if let startTime = exhalationStartTime {
            let duration = Date().timeIntervalSince(startTime)
            print("Stopped exhaling. Duration: \(String(format: "%.2f", duration)) seconds")
            exhaleDurations.append(duration)
        }
        exhalationStartTime = nil
    }
    
    func updateColumn() {
        if isInhaling {
            // Increase saturation gradually
            saturation = min(saturation + 2, 100)
            print("Saturation increasing: \(saturation)")
        } else if isDecreasing && saturation > 0 {
            // Decrease saturation gradually
            saturation = max(saturation - 2, 0)
            print("Saturation decreasing: \(saturation)")
 
        }
    }

    // Add reset function
    func reset() {
        isInhaling = false
        inhalationStartTime = nil
        exhalationStartTime = nil
        columnHeight = 0
        isDecreasing = false
        isRecordingComplete = false
        saturation = 0
        inhaleDurations = []
        exhaleDurations = []
        recordingCurrentIndex = 0
        finalAverages = nil  // Reset the final averages
        print("Breathing state reset")
    }
}

class ViewBreathInputController: NSViewController, NSWindowDelegate {
    var inputWindow: NSWindow?
    private var windowManager: WindowManager?
    private let breathingState: BreathingStateForBreathInput = BreathingStateForBreathInput()
    private var keyMonitor: Any?
    private var animationTimer: Timer?

    private func cleanup() {
        // Clean up
        if let monitor = keyMonitor {
            NSEvent.removeMonitor(monitor)
            keyMonitor = nil
        }
        animationTimer?.invalidate()
        animationTimer = nil
        breathingState.stopInhaling()
        windowManager?.cleanup()
        windowManager = nil
        inputWindow = nil
    }
    
    private func handleClose() {
        inputWindow?.close()  // This will trigger windowWillClose
    }
    
    var breathInputView: some View {
        BreathInputView(breathingState: breathingState) {
            self.handleClose()
        }
    }
    
    // Move the view to its own struct to properly handle state
    struct BreathInputView: View {
        @ObservedObject var breathingState: BreathingStateForBreathInput
        var onClose: () -> Void  // Add close action
        
        var body: some View {
            ZStack {
                // Semi-transparent background
                Color.black.opacity(0.5)
                    .edgesIgnoringSafeArea(.all)
                
                // Content
                VStack(spacing: 20) {
                    Spacer()
                    
                    Text("Record your breath")
                        .font(.system(size: 32, weight: .light))
                        .foregroundColor(.white)
                        .padding()
                        .frame(height: 60)
                    
                    if !breathingState.isRecordingComplete {
                        // Recording progress
                        Text("\(min(breathingState.recordingCurrentIndex + 1, 4))/4")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.white)
                            .frame(height: 40)
                    }
                    
                    if breathingState.isRecordingComplete {
                        VStack(spacing: 10) {
                            Text("Recording complete!")
                                .font(.system(size: 24, weight: .light))
                                .foregroundColor(.white)
                            if let averages = breathingState.finalAverages {
                                Text("Your new breathing pattern:")
                                    .font(.system(size: 20, weight: .light))
                                    .foregroundColor(.white)
                                Text("Inhale: \(String(format: "%.1f", averages.inhale)) seconds")
                                    .font(.system(size: 20, weight: .light))
                                    .foregroundColor(.white)
                                Text("Exhale: \(String(format: "%.1f", averages.exhale)) seconds")
                                    .font(.system(size: 20, weight: .light))
                                    .foregroundColor(.white)
                            }
                        }
                        .multilineTextAlignment(.center)
                        .padding()
                        .frame(height: 100)
                    } else {
                        // Breathing status text
                        Text(breathingState.isInhaling ? "Inhaling..." : 
                            breathingState.isDecreasing ? "Exhaling..." : "Press and hold SPACE to inhale. You should close your eyes")
                            .font(.system(size: 24, weight: .light))
                            .foregroundColor(.white)
                            .padding()
                            .frame(height: 100)
                    }
                    
                    // Circle with HSL animation
                    Circle()
                        .frame(width: 200, height: 200)
                        .foregroundColor(Color(hue: 0.33,
                                            saturation: breathingState.saturation / 100,
                                            brightness: 0.5))
                        .padding()
                    
                    // Timer container with fixed height
                    ZStack {
                        if !breathingState.isRecordingComplete {
                            if let startTime = breathingState.inhalationStartTime {
                                TimelineView(.animation(minimumInterval: 0.1)) { _ in
                                    Text(String(format: "%.1f seconds", Date().timeIntervalSince(startTime)))
                                        .font(.system(size: 20, weight: .light))
                                        .foregroundColor(.white)
                                }
                            } else if let startTime = breathingState.exhalationStartTime {
                                TimelineView(.animation(minimumInterval: 0.1)) { _ in
                                    Text(String(format: "%.1f seconds", Date().timeIntervalSince(startTime)))
                                        .font(.system(size: 20, weight: .light))
                                        .foregroundColor(.white)
                                }
                            }
                        }
                    }
                    .frame(height: 40)
                    
                    // Cancel button
                    Button(action: onClose) {
                        HStack(spacing: 8) {
                            Text("Cancel")
                            Text("(esc)")
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .font(.system(size: 18, weight: .regular))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white.opacity(0.2))
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .frame(height: 50)
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
    
    override func loadView() {
        self.view = NSHostingView(rootView: breathInputView)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func showWindow() {
        if inputWindow == nil {
            setupInputWindow()
        }
        
        // Reset breathing state when window is shown
        breathingState.reset()
        
        inputWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)  // Force focus
        setupKeyMonitoring()
        setupAnimationTimer()
    }
    
    private func setupAnimationTimer() {
        // Remove existing timer if any
        animationTimer?.invalidate()
        
        // Create new timer that updates column height
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            self?.breathingState.updateColumn()
        }
    }
    
    private func setupInputWindow() {
        guard let screen = NSScreen.main else { return }
        
        let window = NSWindow(
            contentRect: screen.frame,
            styleMask: [.borderless],  // Remove .titled to prevent title bar
            backing: .buffered,
            defer: false
        )
        
        window.backgroundColor = .clear
        window.isOpaque = true
        window.level = .statusBar
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        window.contentView = NSHostingView(rootView: breathInputView)
        window.delegate = self
        
        // Allow clicking through the blur to close
        window.ignoresMouseEvents = false
        window.isReleasedWhenClosed = false
        
        self.inputWindow = window
        self.windowManager = WindowManager(window: window, owner: self, name: "BreathInput")
    }
    
    @objc private func handleSpaceChange() {
        print("Space change detected")
        ensureWindowVisibility()
    }
    
    @objc private func handleWindowMove() {
        print("Window moved")
        ensureWindowVisibility()
    }
    
    @objc private func handleWindowVisibility() {
        print("Window visibility changed")
        ensureWindowVisibility()
    }
    
    private func checkWindowVisibility() {
        if let window = inputWindow {
            print("Window isVisible: \(window.isVisible), isOnActiveSpace: \(window.isOnActiveSpace)")
            if !window.isVisible || !window.isOnActiveSpace {
                ensureWindowVisibility()
            }
        }
    }
    
    private func ensureWindowVisibility() {
        if let window = inputWindow {
            print("Ensuring window visibility...")
            window.orderFront(nil)
            window.level = .statusBar
            
            // Make sure window is visible in the current space
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                window.orderFront(nil)
                window.level = .statusBar
            }
        }
    }
    
    private func setupKeyMonitoring() {
        // Remove existing monitor if any
        if let existingMonitor = keyMonitor {
            NSEvent.removeMonitor(existingMonitor)
        }
        
        // Monitor for both key down and key up events
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .keyUp]) { [weak self] event in
            if event.keyCode == 53 { // Esc key
                self?.handleClose()
                return event
            }
            
            if event.keyCode == 49 { // Space key
                if (self?.breathingState.recordingCurrentIndex ?? 0 > 3) {
                    return event
                }

                if event.type == .keyDown && !event.isARepeat {
                    self?.breathingState.stopExhaling()
                    // Start inhaling on initial key down
                    self?.breathingState.startInhaling()
                } else if event.type == .keyUp {
                    // Stop inhaling on key up
                    self?.breathingState.recordingCurrentIndex += 1
                    self?.breathingState.stopInhaling()
                    self?.breathingState.startExhaling()
                }
                return nil // Prevent the system sound by not propagating the space key event
            }
            
            return event
        }
    }
    
    // MARK: - NSWindowDelegate
    
    func windowWillClose(_ notification: Notification) {
        cleanup()  // Only do cleanup here
    }
} 
