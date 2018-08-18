//
//  BaseCollectionViewCell.swift
//  ssg
//
//  Created by pkh on 2017. 12. 20..
//  Copyright © 2017년 emart. All rights reserved.
//

import UIKit

public class BaseCollectionViewCell: UICollectionViewCell  {
    
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


