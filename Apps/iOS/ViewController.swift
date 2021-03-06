//
//  ViewController.swift
//  iOS
//
//  Created by Jim Derry on 10/21/17.
//  Copyright © 2017 Jim Derry. All rights reserved.
//

import SwLibTidy
import UIKit

class ViewController: UIViewController {
    @IBOutlet var textView: UITextView!

    /* Use the same output creator as the sample console application. */
    var myExample = TidyRunner()

    override func viewDidLoad() {
        super.viewDidLoad()

        myExample.output = { arg in
            self.textView.font = UIFont(name: "Menlo", size: 12)
            self.textView.textStorage.append(NSAttributedString(string: "\(arg)\n"))
        }

        textView.text = ""
        myExample.RunTidy()
    }
}
