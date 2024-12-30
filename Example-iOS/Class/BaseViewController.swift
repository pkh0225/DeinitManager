//
//  BaseViewController.swift
//  ssg
//
//  Created by pkh on 2017. 11. 30..
//  Copyright © 2017년 emart. All rights reserved.
//

import UIKit
import DeinitChecker

public class BaseViewController: UIViewController, DeinitChecker {
    public var deinitNotifier: DeinitNotifier?

    override public func viewDidLoad() {
        super.viewDidLoad()
        setDeinitNotifier()
    }
}

