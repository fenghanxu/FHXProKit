//
//  ViewController.swift
//  FHXProKit
//
//  Created by fenghanxu on 07/09/2018.
//  Copyright (c) 2018 fenghanxu. All rights reserved.
//

import UIKit
import FHXProKit

class ViewController: UIViewController {
  
  fileprivate let textField = TextField()

    override func viewDidLoad() {
        super.viewDidLoad()
        textField.wordLimit = 5
        textField.frame = CGRect(x: 100, y: 300, width: 200, height: 25)
        textField.placeholder = "请输入内容"
        view.addSubview(textField)
    }

}

