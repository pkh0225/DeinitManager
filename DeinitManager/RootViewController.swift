//
//  ViewController.swift
//  DeinitManager
//
//  Created by SWIFT on 2018. 8. 18..
//  Copyright © 2018년 SWIFT. All rights reserved.
//

import UIKit

class RootViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        DeinitManager.shared.initRun(true, navigation: self.navigationController)
        self.tableView.register(UITableViewCell.self)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(UITableViewCell.self, for: indexPath)
        cell.textLabel?.numberOfLines = 0
        switch indexPath.row {
        case 0:
            cell.textLabel?.text = "self weak 처리가 되지 않아서 발생하는 문제"
        case 1:
            cell.textLabel?.text = "SubView 에 self가 weak 처리가 되지 않아서 발생하는 문제"
        case 2:
            cell.textLabel?.text = "Cell Closure 안에 tableview가 weak 처리 되지 않아 cell이 deinit이 호출되지 않는 문제"
        case 3:
            cell.textLabel?.text = "Cell Closure 안에 cell이 weak 처리 되지 않아 cell이 deinit이 호출되지 않는 문제"
        case 4:
            cell.textLabel?.text = " 정상"
            
        default:
            break
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case 0:
            DeinitManager.shared.pushViewControllerFromStoryBoard(DeinitCheckViewController.self)
            break
        case 1:
            DeinitManager.shared.pushViewControllerFromStoryBoard(DeinitCheckViewController2.self)
            break
        case 2:
            DeinitManager.shared.pushViewControllerFromStoryBoard(DeinitCheckViewController3.self)
            break
        case 3:
            DeinitManager.shared.pushViewControllerFromStoryBoard(DeinitCheckViewController4.self)
            break
        case 4:
            DeinitManager.shared.pushViewControllerFromStoryBoard(DeinitCheckViewController5.self)
            break
            
        default:
            break
        }
    }

}

