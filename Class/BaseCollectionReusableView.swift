//
//  BaseCollectionReusableView.swift
//  ssg
//
//  Created by pkh on 2017. 12. 20..
//  Copyright © 2017년 emart. All rights reserved.
//

import UIKit

public class BaseCollectionReusableView: UICollectionReusableView, DeinitChecker {
    public var deinitNotifier: DeinitNotifier?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setDeinitNotifier()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setDeinitNotifier()
    }
}
