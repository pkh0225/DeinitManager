//
//  BaseViewController.swift
//  ssg
//
//  Created by pkh on 2017. 11. 30..
//  Copyright © 2017년 emart. All rights reserved.
//

import UIKit

public class BaseViewController: UIViewController {
    var deinitClosure: [VoidClosure] = [VoidClosure]()
    var naviPopClosure: VoidClosure? {
        didSet {
            if naviPopClosure == nil {
                DeinitManager.shared.removeClassData(self)
            }
            else {
                DeinitManager.shared.AddViewControllerKey(self)
            }
        }
    }
    
    func addDeinitClosure(closure: @escaping VoidClosure) {
        deinitClosure.append(closure)
    }
    
    func runDeinitClosure() {
        
        for vc in childViewControllers {
            if let gvc = vc as? BaseViewController {
                gvc.runDeinitClosure()
            }
        }
        
        for closure in deinitClosure {
            closure()
        }
        
    }
    deinit {
//        print("\t<<<<< \(self.className) deinit >>>>>")
        DeinitManager.shared.deinitVC(self)
        DeinitManager.shared.deInitClass(className: self.className)
        runDeinitClosure()
        naviPopClosure?()
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        DeinitManager.shared.addClass(className: self.className)
    }
    
    public class func loadXib() -> Self {
        return self.init(nibName: self.className, bundle: nil)
    }
    
}

