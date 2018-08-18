//
//  BaseView.swift
//  ssg
//
//  Created by pkh on 2018. 6. 15..
//  Copyright © 2018년 emart. All rights reserved.
//

import UIKit

public class BaseView: UIView {
    
    deinit {
//        print("\t<<<<< \(self.className) deinit >>>>>")
        DeinitManager.shared.deInitClass(className: self.className)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        DeinitManager.shared.addClass(className: self.className)
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        DeinitManager.shared.addClass(className: self.className)
    }
}
