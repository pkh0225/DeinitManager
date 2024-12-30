//
//  ViewController.swift
//  DeinitManager
//
//  Created by SWIFT on 2018. 8. 18..
//  Copyright © 2018년 SWIFT. All rights reserved.
//

import UIKit
import DeinitChecker

class RootViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        DeinitManager.shared.isRun = true
        self.navigationController?.title = "DeinitChecker"
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell")!
        cell.textLabel?.numberOfLines = 0
        switch indexPath.row {
        case 0:
            cell.textLabel?.text = "1. self weak 처리가 되지 않아서 발생하는 문제"
        case 1:
            cell.textLabel?.text = "2. SubView 에 self가 weak 처리가 되지 않아서 발생하는 문제"
        case 2:
            cell.textLabel?.text = "3. Cell Closure 안에 tableview가 weak 처리 되지 않아 cell이 deinit이 호출되지 않는 문제"
        case 3:
            cell.textLabel?.text = "4. Cell Closure 안에 cell이 weak 처리 되지 않아 cell이 deinit이 호출되지 않는 문제"
        case 4:
            cell.textLabel?.text = "5. 정상"
            
        default:
            break
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        switch indexPath.row {
        case 0:
            let vc = storyboard.instantiateViewController(withIdentifier: "DeinitCheckViewController1")
            self.navigationController?.pushViewController(vc, animated: true)
            break
        case 1:
            let vc = storyboard.instantiateViewController(withIdentifier: "DeinitCheckViewController2")
            self.navigationController?.pushViewController(vc, animated: true)
            break
        case 2:
            let vc = storyboard.instantiateViewController(withIdentifier: "DeinitCheckViewController3")
            self.navigationController?.pushViewController(vc, animated: true)
            break
        case 3:
            let vc = storyboard.instantiateViewController(withIdentifier: "DeinitCheckViewController4")
            self.navigationController?.pushViewController(vc, animated: true)
            break
        case 4:
            let vc = storyboard.instantiateViewController(withIdentifier: "DeinitCheckViewController5")
            self.navigationController?.pushViewController(vc, animated: true)
            break
            
        default:
            break
        }
    }

}

