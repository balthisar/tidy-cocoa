//
//  ViewController.swift
//  gui
//
//  Created by Jim Derry on 8/10/17.
//  Copyright © 2017 Jim Derry. All rights reserved.
//

import Cocoa
import LibTidy

class ViewController: NSViewController {

    @IBOutlet weak var versionLabel: NSTextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        versionLabel.stringValue = tidyLibraryVersion()
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

