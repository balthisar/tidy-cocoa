//
//  ViewController.swift
//  ios
//
//  Created by Jim Derry on 10/19/17.
//  Copyright © 2017 Jim Derry. All rights reserved.
//

import UIKit
import SwLibTidy

class ViewController: UIViewController {

    @IBOutlet weak var mversionLabel: UILabel!
    @IBOutlet weak var mtextView: UITextView!

    /* Use the same output creator as the sample console application. */
    var myExample = TidyRunner.init()

    override func viewDidLoad() {
        super.viewDidLoad()

        myExample.output = { arg in
            self.mtextView.font = UIFont(name: "Menlo", size: 12)
            self.mtextView.textStorage.append(NSAttributedString(string: "\(arg)\n"))
        }

        mversionLabel.text = "Tidy is version \(tidyLibraryVersion()), platform is \(tidyPlatform() ?? "None")."
        self.mtextView.text = "";
        myExample.RunTidy()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

