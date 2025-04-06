//
//  AppDelegate.swift
//  help_me_breath
//
//  Created by Huy Phát Phạm  on 27/3/25.
//

import Cocoa
import SwiftUI
import HotKey

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    // MARK: - Properties
    static var shared: AppDelegate?
    private(set) var window: NSWindow!
    private(set) var statusBarController: StatusBarController!
    private(set) var breathInputController: ViewBreathInputController?
    private var hotKey: HotKey?
    private var localKeyMonitor: Any?
    
    static func main() {
        let app = NSApplication.shared
        app.setActivationPolicy(.accessory) // Set this before setting the delegate
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }

    // MARK: - Initialization
    override init() {
        super.init()
        NSApplication.shared.setActivationPolicy(.accessory)
    }
    
    // MARK: - Application Lifecycle
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        print("did launch")
        AppDelegate.shared = self
        
        // Create status bar first since we're a menu bar app
        statusBarController = StatusBarController()
        
        // Setup global shortcut
        setupKeyMonitoring()
        
        // Automatically show the breathing dot when the app starts
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            print("Show breath dot")
            self?.statusBarController?.showBreathDot()
        }
    }
    
    // MARK: - Key Monitoring
    func setupKeyMonitoring() {
        print("Setup key monitoring")
        hotKey = HotKey(key: .f8, modifiers: [.command])
        
        // Set the key down handler
        hotKey?.keyDownHandler = { [weak self] in
            print("F8 pressed globally")
            self?.showBreathInput()
        }
        
        // Keep local monitor for when app is active
        localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if self?.handleF8KeyPress(event) == true {
                return nil // Consume the event
            }
            return event
        }
    }
    
    private func handleF8KeyPress(_ event: NSEvent) -> Bool {
        print("Handle F8 key press: ", event.keyCode)
        // Check for F8 key (keycode 100)
        if event.keyCode == 100 {
            showBreathInput()
            return true
        }
        return false
    }
    
    private func showBreathInput() {
        print("Show breath input")
        if breathInputController == nil {
            breathInputController = ViewBreathInputController()
        }
        breathInputController?.showWindow()
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Clean up local monitor
        if let monitor = localKeyMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
    
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
}

