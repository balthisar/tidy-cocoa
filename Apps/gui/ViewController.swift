//
//  ViewController.swift
//  gui
//
//  Created by Jim Derry on 8/10/17.
//  Copyright © 2017 Jim Derry. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    @IBOutlet var textView: NSTextView!

    /* Use the same output creator as the sample console application. */
    var myExample = TidyRunner()

    override func viewDidLoad() {
        super.viewDidLoad()

        myExample.output = { arg in
            self.textView.font = NSFont(name: "Menlo", size: 12)
            self.textView.textStorage?.append(NSAttributedString(string: "\(arg)\n"))
            self.textView.font = NSFont(name: "Menlo", size: 12)
        }

        myExample.RunTidy()
    }

    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
}
