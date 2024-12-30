//
//  DeinitCheckViewController3.swift
//  DeinitManager
//
//  Created by SWIFT on 2018. 8. 18..
//  Copyright © 2018년 SWIFT. All rights reserved.
//

import UIKit

class DeinitCheckViewController4: BaseViewController, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
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

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DeinitCheckTableViewCell", for: indexPath) as! DeinitCheckTableViewCell
        cell.textLabel?.text = "row: \(indexPath.row)"
        // 문제 코드
//        cell.testClosure = {
//            print(cell)
//        }
        
        // 정상 문제 코드 1
        cell.testClosure = { [weak cell] in
            guard let cell = cell else { return }
            print(cell)
        }
        
       
        return cell
    }
}
