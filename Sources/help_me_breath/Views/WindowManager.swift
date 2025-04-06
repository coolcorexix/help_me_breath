import Cocoa

class WindowManager {
    private weak var window: NSWindow?
    private weak var owner: AnyObject?
    private let name: String
    
    init(window: NSWindow, owner: AnyObject, name: String = "Window") {
        self.window = window
        self.owner = owner
        self.name = name
        setupWindow()
    }
    
    private func setupWindow() {
        guard let window = window else { return }
        
        // Configure window properties
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = false
        window.level = .statusBar
        window.collectionBehavior = [.canJoinAllSpaces, .participatesInCycle, .fullScreenAuxiliary]
        
        // Hide title bar but keep window manageable
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.standardWindowButton(.closeButton)?.isHidden = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true
        
        print("Setting up \(name) observers...")
        
        // Observe space changes
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(handleSpaceChange),
            name: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSpaceChange),
            name: NSWindow.didChangeScreenNotification,
            object: window
        )
        
        // Observe window movement
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleWindowMove),
            name: NSWindow.didMoveNotification,
            object: window
        )
        
        print("Debug: \(name) frame = \(window.frame)")
        print("Debug: \(name) level = \(window.level.rawValue)")
        print("Debug: \(name) collection behavior = \(window.collectionBehavior.rawValue)")
    }
    
    @objc private func handleSpaceChange() {
        print("\(name): Space change detected")
        ensureWindowVisibility()
    }
    
    @objc private func handleWindowMove() {
        print("\(name): Window moved")
        ensureWindowVisibility()
    }
    
    private func ensureWindowVisibility() {
        if let window = window {
            print("\(name): Ensuring window visibility...")
            window.orderFront(nil)
            window.level = .statusBar
            
            // Make sure window is visible in the current space
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                window.orderFront(nil)
                window.level = .statusBar
            }
        }
    }
    
    func cleanup() {
        // Remove all observers
        NSWorkspace.shared.notificationCenter.removeObserver(self)
        NotificationCenter.default.removeObserver(self)
    }
    
    deinit {
        cleanup()
    }
} 