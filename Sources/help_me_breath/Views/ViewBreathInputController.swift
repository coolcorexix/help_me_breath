import SwiftUI
import Cocoa

// State object to manage breathing state
class BreathingStateForBreathInput: ObservableObject {
    @Published var isInhaling = false
    @Published var inhalationStartTime: Date?
    @Published var columnHeight: CGFloat = 0
    @Published var isDecreasing = false
    
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
        }
        inhalationStartTime = nil
    }
    
    func updateColumn() {
        if isInhaling {
            // Increase column height gradually
            columnHeight = min(columnHeight + 2, 300)
            print("Column height updated: \(columnHeight)")
        } else if isDecreasing && columnHeight > 0 {
            // Decrease column height gradually
            columnHeight = max(columnHeight - 2, 0)
            print("Column decreasing: \(columnHeight)")
            if columnHeight == 0 {
                isDecreasing = false
            }
        }
    }
}

class ViewBreathInputController: NSViewController, NSWindowDelegate {
    var inputWindow: NSWindow?
    private var windowManager: WindowManager?
    private let breathingState = BreathingStateForBreathInput()
    private var keyMonitor: Any?
    private var animationTimer: Timer?
    
    var breathInputView: some View {
        BreathInputView(breathingState: breathingState)
    }
    
    // Move the view to its own struct to properly handle state
    struct BreathInputView: View {
        @ObservedObject var breathingState: BreathingStateForBreathInput
        
        var body: some View {
            ZStack {
                // Semi-transparent background
                Color.black.opacity(0.5)
                    .edgesIgnoringSafeArea(.all)
                
                // Content
                VStack(spacing: 20) {
                    Text("Breath Input")
                        .font(.system(size: 32, weight: .light))
                        .foregroundColor(.white)
                        .padding()
                    
                    // Breathing status text
                    Text(breathingState.isInhaling ? "Inhaling..." : 
                         breathingState.isDecreasing ? "Exhaling..." : "Press and hold SPACE to inhale")
                        .font(.system(size: 24, weight: .light))
                        .foregroundColor(.white)
                        .padding()
                    
                    // Column animation
                    ZStack(alignment: .bottom) {
                        // Column container
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 60, height: 300)
                        
                        // Animated green column
                        Rectangle()
                            .foregroundColor(.green)
                            .frame(width: 60, height: breathingState.columnHeight)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .padding()
                    .background(Color.red.opacity(0.3)) // Debug background
                    
                    if let startTime = breathingState.inhalationStartTime {
                        TimelineView(.animation(minimumInterval: 0.1)) { _ in
                            Text(String(format: "%.1f seconds", Date().timeIntervalSince(startTime)))
                                .font(.system(size: 20, weight: .light))
                                .foregroundColor(.white)
                        }
                    }
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
        
        // Make window key and front most
        inputWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)  // This ensures our app becomes active
        
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
            styleMask: [.borderless, .titled],
            backing: .buffered,
            defer: false
        )
        
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
                self?.inputWindow?.close()
                return nil
            }
            
            if event.keyCode == 49 { // Space key
                if event.type == .keyDown && !event.isARepeat {
                    // Start inhaling on initial key down
                    self?.breathingState.startInhaling()
                } else if event.type == .keyUp {
                    // Stop inhaling on key up
                    self?.breathingState.stopInhaling()
                }
                return nil // Consume the event
            }
            
            return event
        }
    }
    
    // MARK: - NSWindowDelegate
    
    func windowWillClose(_ notification: Notification) {
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
} 
