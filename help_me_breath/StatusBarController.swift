import AppKit
import Cocoa
import SwiftUI

class StatusBarController {
    private var statusItem: NSStatusItem
    private var breathDotController: ViewBreathDotController?

    init() {
        // Create a menu bar item with fixed width to ensure visibility
        statusItem = NSStatusBar.system.statusItem(withLength: 28.0)
        
        if let button = statusItem.button {
            // Use a more visible icon
            if let image = NSImage(systemSymbolName: "lungs.fill", accessibilityDescription: "Help me breath") {
                image.size = NSSize(width: 16.0, height: 16.0)
                image.isTemplate = true  // This makes it adapt to system dark/light mode
                button.image = image
            }
            button.imagePosition = .imageLeft
        }

        // Create a menu
        let menu = NSMenu()
        
        // Add menu item to show breathing dot
        let showBreathDotMenuItem = NSMenuItem(title: "Show Breathing Dot", action: #selector(showBreathDot), keyEquivalent: "b")
        showBreathDotMenuItem.target = self
        menu.addItem(showBreathDotMenuItem)
        
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))
        
        statusItem.menu = menu
    }

    
    @objc public func showBreathDot() {
        // Create the breath dot controller if it doesn't exist
        if breathDotController == nil {
            breathDotController = ViewBreathDotController()
            // Make sure it loads its view
            breathDotController?.loadView()
            breathDotController?.viewDidLoad()
        }
        
        // Make sure the window is displayed
        breathDotController?.circleWindow?.makeKeyAndOrderFront(nil)
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}
