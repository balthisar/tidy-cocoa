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
    @IBOutlet weak var textView: NSTextView!

    /* Use the same output creator as the sample console application. */
    var myExample = TidyRunner.init()

    override func viewDidLoad() {
        super.viewDidLoad()

        myExample.output = { arg in
            self.textView.font = NSFont(name: "Menlo", size: 12)
            self.textView.textStorage?.append(NSAttributedString(string: "\(arg)\n"))
        }

        versionLabel.stringValue = tidyLibraryVersion()
        myExample.RunTidy()
    }


    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

}

