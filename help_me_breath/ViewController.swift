//
//  ViewController.swift
//  help_me_breath
//
//  Created by Huy Phát Phạm  on 27/3/25.
//

import Cocoa

class ViewController: NSViewController {
    override func loadView() {
        let view = NSView()
        view.setFrameSize(NSSize(width: 300, height: 200))
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.white.cgColor
        self.view = view
        
        let label = NSTextField(labelWithString: "Hello, macOS!")
        label.font = NSFont.systemFont(ofSize: 18)
        label.alignment = .center
        label.frame = CGRect(x: 50, y: 80, width: 200, height: 30)
        view.addSubview(label)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        print("view did load")

        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

