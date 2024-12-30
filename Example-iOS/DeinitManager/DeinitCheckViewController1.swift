//
//  DeinitCheckViewController.swift
//  DeinitManager
//
//  Created by SWIFT on 2018. 8. 18..
//  Copyright © 2018년 SWIFT. All rights reserved.
//

import UIKit

class DeinitCheckViewController1: BaseViewController {

    var testClosure: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()

        /*
         self 가 weak 처리 되지 않아 self deinit이 호출되지 않는 문제 코드
         */
        testClosure = {
            print(self)
        }
        
        /*
         정상 코드
         아래 코드 주석 풀어서 확인
         */
//        testClosure = { [weak self] in
//            guard let `self` = self else { return }
//            print(self)
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
