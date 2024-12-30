//
//  BaseTableViewCell.swift
//  ssg
//
//  Created by pkh on 2017. 12. 20..
//  Copyright © 2017년 emart. All rights reserved.
//

import UIKit

public class BaseTableViewCell: UITableViewCell, DeinitChecker {
    public var deinitNotifier: DeinitNotifier?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setDeinitNotifier()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setDeinitNotifier()
    }
    
}
