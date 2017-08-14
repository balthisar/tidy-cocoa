//
//  ViewController.swift
//  gui
//
//  Created by Jim Derry on 8/10/17.
//  Copyright © 2017 Jim Derry. All rights reserved.
//

import Cocoa
import SwLibTidy

/* In the GUI app we don't want to statically bind like we do in the console
   app, although presumably we could. In this case we simply want to link to
   the framework, and so we're not including any of the framework files into
   our build. Instead, the framework is linked dynamically, and we have to
   import LibTidy above.
 */

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

