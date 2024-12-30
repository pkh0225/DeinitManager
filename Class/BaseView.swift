//
//  BaseView.swift
//  ssg
//
//  Created by pkh on 2018. 6. 15..
//  Copyright © 2018년 emart. All rights reserved.
//

import UIKit

public class BaseView: UIView, DeinitChecker {
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
