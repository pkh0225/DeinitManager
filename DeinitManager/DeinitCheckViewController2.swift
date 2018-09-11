//
//  DeinitCheckViewController.swift
//  DeinitManager
//
//  Created by SWIFT on 2018. 8. 18..
//  Copyright © 2018년 SWIFT. All rights reserved.
//

import UIKit

class DeinitCheckViewController2: BaseViewController {

    @IBOutlet weak var testView: DeinitCheckView!
    
    var testView2 = DeinitCheckView()
    var testView3 = DeinitCheckView()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
        // 문제 코드
        testView.testClosure = {
            print(self.testView)
        }
        
        // 정상코드 1
//        testView.testClosure = { [weak testView] in
//            guard let testView = testView else { return }
//            print(testView)
//        }
        
        // 정상코드 2
//        testView.testClosure = { [weak self] in
//            guard let `self` = self else { return }
//            print(self.testView)
//
//            self.testView2.testClosure = {
//                print(self.testView2)
//
//                self.testView3.testClosure = {
//                    print(self.testView3)
//                }
//            }
//        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
