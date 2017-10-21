//
//  ViewController.swift
//  iOS
//
//  Created by Jim Derry on 10/21/17.
//  Copyright © 2017 Jim Derry. All rights reserved.
//

import UIKit
import SwLibTidy

class ViewController: UIViewController {

    @IBOutlet weak var textView: UITextView!

    override func viewDidLoad() {
        super.viewDidLoad()

//        myExample.output = { arg in
//            self.textView.font = UIFont(name: "Menlo", size: 12)
//            self.textView.textStorage.append(NSAttributedString(string: "\(arg)\n"))
//        }

        self.textView.textStorage.append(NSAttributedString( string: "HELLO" ) )
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

