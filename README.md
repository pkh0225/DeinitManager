# 🚥 Deinit Manager

## 목표
- 모든 푸시&팝 이벤트에 대해 직관적으로 메모리 해제를 확인하세요!
- 🚧 Check Memory Leak in every push & pop events!


## 🚁 작동 방식
1. Navigation Push 후 Pop을 하면 Pop 후 약 1.5초 간 터치가 막혀 클릭이 불가합니다. 
2. 만약 해제 되지 않은 view 와 controller가 있다면 해당 이름이 팝업에 리스트됩니다.
3. 만약 모든 인스턴스가 정상 해제 되었다면 💯점 토스트 팝업이 띄워집니다.  ⛱


## 🚁 How it works
1. There is 1.5 sec UI leg following the pop action. You are not able to touch the screen for the time being. 
2. If memory leaked happens, leaked views and controllers will be listed on the popup.
3. If all the instances deinited, then ok💯🆗 popup will be toasted! 🥪


## Test Cases

![blogimg](https://github.com/pkh0225/DeinitManager/blob/master/screen.png)



## ☹︎ deinit fail

![blogimg](https://github.com/pkh0225/DeinitManager/blob/master/fail.png)

```
// self 가 weak 처리 되지 않아 self deinit이 호출되지 않는 경우
testClosure = {
            print(self)
        }
```


## ☺︎ deinit success

![blogimg](https://github.com/pkh0225/DeinitManager/blob/master/ok.png)

```
testClosure = { [weak self] in
	guard let `self` = self else { return }
	print(self)
}
```

<br>
<br>

## Core functions

```
public class DeinitManager: NSObject {
    static public let shared = DeinitManager()
    
    public struct DeinitInfo {
        var className = ""
        var count: Int = 0
    }

    
    public var _isRun = true
    public var isRun: Bool {
        get {
            return _isRun
        }
        set {
            _isRun = isbeta && newValue
        }
    }
    public let isbeta = betaCheck()
    public var label: UILabel!
    public var deinitInfoList = [[String: DeinitInfo]]()
    
    public var nvCount: Int = 0
    private(set) var isMemoryRepory: Bool = false
    
    public var deinitInfoArray = [UIViewController]()
    
    private override init() { }
    
    public func initRun(_ value: Bool, navigation: UINavigationController?) {
        self.isRun = value
        self.navigation = navigation
        guard self._isRun else { return }
        
        self.startMemoryReport()
    }
    
    public func startMemoryReport() {
        guard isMemoryRepory == false else { return }
        
        gcd_main_after(1) {
            self.label = UILabel(frame: CGRect(x: 200, y: self.safeAreaInsets.top, width: 80, height: 20))
            self.label.backgroundColor = UIColor(red: 0.5, green: 0.2, blue: 0.1, alpha: 0.7)
            self.label.textColor = .yellow
            UIApplication.shared.keyWindow?.addSubview(self.label)
            
            gcd_thread {
                self.isMemoryRepory = true
                while self._isRun {
                    //                usleep(1000000) //will sleep for 1 second
                    usleep(500000) //will sleep for 0.5 seconds
                    
                    let byteCount = self.memoryReport()
                    let bcf = ByteCountFormatter()
                    bcf.allowedUnits = [.useMB]
                    bcf.countStyle = .memory
//                    let string = bcf.string(fromByteCount: Int64(byteCount))
                    let string = bcf.string(fromByteCount: Int64(byteCount))
                    
                    gcd_main_safe {
                        self.label.text = string
                    }
                }
                self.isMemoryRepory = false
                self.deinitInfoList.removeAll()
                gcd_main_safe {
                    self.label.removeFromSuperview()
                }
                
            }
        }
        
    }
    
    public func startCheck(_ className: String) {
        guard self._isRun else { return }
        var obj = DeinitInfo()
        obj.className = className
        obj.count = 0
        deinitInfoList.append(["\(className)": obj])
    }
    
    
    /// 네비게이션에 들어가는 컨트롤러를 키로 등록한다.
    ///
    /// - Parameter vc: 네비게이션에 들어가는 컨트롤러
    public func AddViewControllerKey(_ vc:  UIViewController) {
        guard _isRun, deinitInfoList.count > 0 else { return }
        var dic = deinitInfoList[deinitInfoList.count - 1]
        let point = unsafeBitCast(vc, to: Int.self)
        dic.updateValue(DeinitInfo(), forKey: "\(point)")
        deinitInfoList[deinitInfoList.count-1] = dic
    }
    
    
    public func addClass(className: String) {
//        print("add \(className)")
        
        guard self._isRun, deinitInfoList.count > 0 else { return }
        var dic = deinitInfoList[deinitInfoList.count - 1]
        
        if var info = dic[className] {
            info.count += 1
            dic.updateValue(info, forKey: className)
        }
        else {
            var obj = DeinitInfo()
            obj.className = className
            obj.count = 1
            dic.updateValue(obj, forKey: className)
        }
        deinitInfoList[deinitInfoList.count-1] = dic
        
    }
    
    public func deInitClass(className: String)  {
//        print("deinit \(className)")
        guard _isRun, deinitInfoList.count > 0 else { return }
        var dic = deinitInfoList[deinitInfoList.count - 1]
        
        if var info = dic[className] {
            info.count -= 1
            dic.updateValue(info, forKey: className)
            deinitInfoList[deinitInfoList.count-1] = dic
        }
    }
    
    public func removeClassData(_ vc: UIViewController) {
        guard _isRun, deinitInfoList.count > 0 else { return }
        let point = unsafeBitCast(vc, to: Int.self)
        for (idx,dic) in deinitInfoList.enumerated() {
            if let _ = dic["\(point)"] {
                deinitInfoList.remove(at: idx)
                return
            }
        }
    }
    
    public func removeClassData(_ point: String) {
        guard _isRun, deinitInfoList.count > 0 else { return }
        for (idx,dic) in deinitInfoList.enumerated() {
            if let _ = dic["\(point)"] {
                deinitInfoList.remove(at: idx)
                return
            }
        }
    }
    
    public func removeToClassData(_ vc: UIViewController) {
        guard _isRun, deinitInfoList.count > 0 else { return }
        let point = unsafeBitCast(vc, to: Int.self)
        for dic in deinitInfoList.reversed() {
            if let _ = dic["\(point)"] {
                return
            }
            deinitInfoList.removeLast()
        }
    }
    
    public func getDeinitInfo(_ point: String) ->  [String: DeinitInfo]? {
        for (_,dic) in self.deinitInfoList.enumerated() {
            if let _ = dic["\(point)"] {
                return dic
            }
        }
        return nil
    }
    
    public func deinitCheck(_ className: String, _ point: String) {
        print("\n\t\t<<<<<😄 \(className) deinit 👏🏻>>>>>\n")
        guard self._isRun else { return }
        
        gcd_main_safe {
            UIApplication.shared.keyWindow?.isUserInteractionEnabled = false
        }
        gcd_thread_after(1.5, {
            
            func endFunc() {
                self.removeClassData(point)
                gcd_main_safe {
                    UIApplication.shared.keyWindow?.isUserInteractionEnabled = true
                }
            }

            guard let dic = self.getDeinitInfo(point) else {
                endFunc()
                return
            }
            
            var count: Double = 0
            for (_, value) in dic {
                if value.count > 0 {
                    count += 1
                }
            }
            if count > 0 {
//                print("deinitCheck sleep count = \(count)")
             
                gcd_thread_after( count * 0.2, {
                    guard let dic = self.getDeinitInfo(point) else {
                        endFunc()
                        return
                    }
                    
                    var list = [String]()
                    list.reserveCapacity(dic.count)
                    for (key, value) in dic {
                        if value.count > 0 {
                            list.append("\(key) : \(value.count)")
                        }
                    }
                    
                    if list.count > 0 {
                        self.makeView(list: list, className: className)
                    }
                    else {
                        self.checkOK(className)
                    }
                    
                    endFunc()
                    
                    
                })
            }
            else {
                self.checkOK(className)
                endFunc()
            }
            
            
        })
    }
    
    public func checkOK(_ className : String) {
        gcd_main_safe {
            if let window = UIApplication.shared.keyWindow {
                let string = "\n ---- \(className) ----\n ---- deinitCheck OK  💯 ---- \n"
                print(string)
                
                let wrapperView = UIView()
                wrapperView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.7)
                wrapperView.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin, .flexibleTopMargin, .flexibleBottomMargin]
                wrapperView.layer.cornerRadius = 10
                window.addSubview(wrapperView)
                
                let messageLabel = UILabel()
                messageLabel.text = string
                messageLabel.numberOfLines = 0
                messageLabel.backgroundColor = .clear
                messageLabel.textColor = .white
                messageLabel.sizeToFit()
                wrapperView.addSubview(messageLabel)
                
                wrapperView.frame.size = CGSize(width: messageLabel.frame.size.width + 60, height: messageLabel.frame.size.height + 50)
                messageLabel.center = CGPoint(x: wrapperView.frame.width / 2.0, y: wrapperView.frame.height / 2.0)
                let screenSize = UIScreen.main.bounds.size
                wrapperView.center = CGPoint(x: screenSize.width / 2.0, y: screenSize.height / 2.0)
                
                gcd_main_after(2.0, {
                    wrapperView.removeFromSuperview()
                })
                
            }
        }
    }
    
    public func makeView(list: [String], className: String?) {
        guard list.count > 0 else { return }
        gcd_main_safe {
            var string = "\n ⚠️😡 Warning -----"
            if let className = className {
                string += "\n 👊🏻 \(className) -----"
            }
            string += "\n 💣 deinit Check Fail -----"
            string += "\n ⬇️ 해제 되지 않은 메모리를 빼주세요 -----"
            string += "\n ------------------------------- \n"
            string += "\n\n \(list.joined(separator: "\n"))"
            string += "\n ------------------------------- \n"
            print(string)
            
            let screenSize = UIScreen.main.bounds.size
            var view: UIView? = UIView(frame: CGRect(x: 10,
                                                     y: self.safeAreaInsets.top + 10,
                                                     width: screenSize.width - 20 ,
                                                     height: screenSize.height - 20 - self.safeAreaInsets.top - self.safeAreaInsets.bottom))
            view?.clipsToBounds = true
            UIApplication.shared.keyWindow?.addSubview(view!)
            let textView = UITextView(frame: CGRect(x: 0, y: 0, width: view!.frame.size.width, height: view!.frame.size.height - 45))
            textView.backgroundColor = .red
            textView.isEditable = false
            textView.font = UIFont.systemFont(ofSize: 14)
            textView.text = string
            view?.addSubview(textView)
            let btn = UIButton(frame: CGRect(x: 0, y: textView.frame.size.height, width: textView.frame.size.width / 2, height: 45))
            btn.backgroundColor = .green
            btn.setTitle("닫기", for: .normal)
            btn.setTitleColor(.black, for: .normal)
            view?.addSubview(btn)
            btn.addAction(for: .touchUpInside) {
                view?.removeFromSuperview()
                view = nil
            }
            
            let btn2 = UIButton(frame: CGRect(x: textView.frame.size.width / 2, y: textView.frame.size.height, width: textView.frame.size.width / 2, height: 45))
            btn2.backgroundColor = .blue
            btn2.setTitle("초기화", for: .normal)
            btn2.setTitleColor(.black, for: .normal)
            view?.addSubview(btn2)
            btn2.addAction(for: .touchUpInside) { [weak self] () in
                guard let `self` = self else { return }
                self.deinitInfoList.removeAll()
                view?.removeFromSuperview()
                view = nil
            }
        }
        
    }
    
    public func memoryReport() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout.size(ofValue: info) / MemoryLayout<integer_t>.size)
        let kerr = withUnsafeMutablePointer(to: &info) { infoPtr in
            return infoPtr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { (machPtr: UnsafeMutablePointer<integer_t>) in
                return task_info( mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), machPtr, &count)
            }
        }
        guard kerr == KERN_SUCCESS else {
            return 0
        }
        
        return info.resident_size
        
    }
    
    public class func betaCheck() -> Bool {
        guard let bundleIdentifier = Bundle.main.bundleIdentifier else {
            return false
        }
        
        guard bundleIdentifier.range(of: "beta") != nil else {
            return false
        }
        
        return true
    }
    
    public var safeAreaInsets : UIEdgeInsets {
        
        if #available(iOS 11.0, *) , self.isIPhoneXScreen() {
            return UIApplication.shared.windows[0].safeAreaInsets
        }
        else {
            return UIEdgeInsetsMake(UIApplication.shared.statusBarFrame.size.height, 0, 0, 0)
        }
    }
    
    public func isIPhoneXScreen() -> Bool {
        if UIApplication.shared.windows.count <= 0 {
            return false
        }
        if #available(iOS 11.0, *) {
            let inset: UIEdgeInsets = UIApplication.shared.windows[0].safeAreaInsets
            if inset.bottom == 0 && inset.top == 0 && inset.right == 0 && inset.left == 0 {
                return false
            }
            else {
                return true
            }
        }
        else {
            return false
        }
    }
    
    
    //MARK: - Navigation
    private var preViewControllers = [UIViewController]()
    private var popVCDic = [String: String]()
    
    weak public var navigation: UINavigationController? {
        didSet {
            navigation?.delegate = self
        }
    }
    
    public func popToRootViewController(animated: Bool) {
        guard let navigation = self.navigation else { return }
        if DeinitManager.shared._isRun {
            DeinitManager.shared.deinitInfoList.removeAll()
        }
        navigation.popToRootViewController(animated: animated)
    }
    
    public func pushEvent(fromVC: UIViewController?, toVC: UIViewController) {
        if DeinitManager.shared._isRun {
            print("\t\t *** ⛳️ pushEvent \(toVC.className) ⛳️ ***")
        }
    }
    
    public func popEvent(_ vcs: [UIViewController], toVC: UIViewController) {
        print("\t\t *** 🌪 popEvent 🌪 ***")
        if DeinitManager.shared._isRun {
            for vc in vcs {
                print("\t\t *** \(vc.className) ***")
                let point = unsafeBitCast(vc, to: Int.self)
                popVCDic.updateValue(vc.className, forKey: "\(point)")
            }
            
            UIApplication.shared.keyWindow?.isUserInteractionEnabled = false
            gcd_main_after(2 + (Double(vcs.count) * 0.2)) {
                defer {
                    UIApplication.shared.keyWindow?.isUserInteractionEnabled = true
                }
                guard self.popVCDic.keys.count > 0 else { return }
                
                var list = [String]()
                for (k,v) in self.popVCDic {
                    list.append(v)
                    DeinitManager.shared.removeClassData(k)
                }
                
                var string = "\n ----- ⚠️😡 Warning - deinit Check Fail 👊🏻💣 -----"
                string += "\n ---- ⬇️ 해제 되지 않은 메모리를 빼주세요 -----"
                string += "\n\n\(list.joined(separator: "\n"))"
                string += "\n\n --------------------------------------------- \n"
                print(string)
                DeinitManager.shared.makeView(list: list, className: nil)
                self.popVCDic.removeAll()
            }
            
            
        }
    }
    
    public func deinitVC(_ vc: UIViewController) {
        let point = unsafeBitCast(vc, to: Int.self)
        popVCDic.removeValue(forKey: "\(point)")
    }
    
    @discardableResult
    public func pushViewControllerFromStoryBoard<T:BaseViewController>(_ classType: T.Type, storyBoardName: String = "Main", animated: Bool = true) -> T {
        
        DeinitManager.shared.startCheck("\(classType.className)")
        let storyboard = UIStoryboard(name: storyBoardName, bundle: Bundle.main)
        let vc = storyboard.instantiateViewController(withIdentifier: classType.className) as! BaseViewController
        let className = vc.className
        let point = "\(unsafeBitCast(vc, to: Int.self))"
        vc.naviPopClosure = {
            DeinitManager.shared.deinitCheck("\(className)", point)
        }
        self.navigation?.pushViewController(vc, animated: animated)
        
        return vc as! T
    }
    
    @discardableResult
    public func pushViewControllerFromXib<T:BaseViewController>(_ classType: T.Type, animated: Bool = true) -> T {
        
        DeinitManager.shared.startCheck("\(classType.className)")
        let className = classType.className
        let vc = classType.loadXib()
        let point = "\(unsafeBitCast(vc, to: Int.self))"
        vc.naviPopClosure = {
            DeinitManager.shared.deinitCheck("\(className)", point)
        }
        self.navigation?.pushViewController(vc, animated: animated)
        
        return vc
    }
    
    @discardableResult
    public func pushViewController<T:BaseViewController>(_ classType: T.Type, animated: Bool = true) -> T {
        
        DeinitManager.shared.startCheck("\(classType.className)")
        let className = classType.className
        let vc = classType.init()
        let point = "\(unsafeBitCast(vc, to: Int.self))"
        vc.naviPopClosure = {
            DeinitManager.shared.deinitCheck("\(className)", point)
        }
        self.navigation?.pushViewController(vc, animated: animated)
        
        return vc
    }
    
}

```