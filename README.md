# 🚥 Deinit Manager

[![SwiftPM compatible](https://img.shields.io/badge/SwiftPM-compatible-brightgreen.svg)](https://swift.org/package-manager/)

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

public class BaseViewController: UIViewController, DeinitChecker {
    public var deinitNotifier: DeinitNotifier?

    override public func viewDidLoad() {
        super.viewDidLoad()
        setDeinitNotifier()
    }
}

DeinitChecker Protocol 채택 후 객체 생성자에서 setDeinitNotifier() 함 수 호출해 주면 됨 
 - 꼭 base처럼 상속 구조 아니여도 상관 없음 그냥 프로토콜만 체택하면 그 객체는 체크가 가능해 짐
 - 단 푸시, 팝을 하는 기준이 되는 ViewController는 하나는 꼭 있어야 함

DeinitManager.shared.isRun = true  해준 후 동작함 끄고 싶을땐 false 처리 하면 됨


아래처럼 weak 처리 안되어 있을 시 메모리 해제 해지 않아서 오류 팝업 생성됨 
testClosure = {
	guard let `self` = self else { return }
	print(self)
}
```

<br>
<br>

## Core functions

```
public final class DeinitManager {
    final class VCInfoClass: Equatable {
        static func == (lhs: VCInfoClass, rhs: VCInfoClass) -> Bool {
            lhs === rhs
        }

        final class ObjectInfo: Equatable {
            static func == (lhs: ObjectInfo, rhs: ObjectInfo) -> Bool {
                lhs === rhs
            }

            var name: String
            var count: Int = 1
            init(name: String) {
                self.name = name
            }
        }

        var address: Int
        var vcName: String
        var objects = [ObjectInfo]()
        init(_ vc: String, address: Int) {
            self.vcName = vc
            self.address = address
        }
    }

    static let shared: DeinitManager = { return DeinitManager() }()
    private init() {}

    public var isRun: Bool = false {
        didSet {
            if isRun {
                UIViewController.enableSwizzleMethodForViewWillDisappear()
                startMemoryReport()
            }
            else {
                removeAll()
                UIViewController.disableSwizzleMethodForViewWillDisappear()
            }
        }
    }

    private var workItem: DispatchWorkItem? // 작업을 관리할 변수
    private var vcInfos = [VCInfoClass]()
    private(set) var isMemoryRepory: Bool = false
    private var memoryLabel: UILabel?


    private func removeAll() {
        self.vcInfos.removeAll()
    }

    public func checkPopViewController(_ name: String, address: Int) {
        guard isRun else { return }
        guard self.vcInfos.last?.vcName == name, self.vcInfos.last?.address == address else { return }
//        print("checkPopViewController name: \(name), address: \(address)")

        // 이전 작업 취소 (있다면)
        workItem?.cancel()

        // 새 작업 생성
        workItem = DispatchWorkItem { [weak self] in
            guard let self else { return }
            if self.vcInfos.contains(where: { $0.vcName == name && $0.address == address }) {
                let string = """
                ------ Warning -------
                👊🏻  \(name)  👊🏻
                💣 deinit Check Fail -----
                ⬇️ 해제 되지 않은 메모리를 빼주세요 -----
                --------------------------------

                    \(name)
                
                -------------------------------
                """
                print(string)
                self.makeView(value: string)
            }
        }

        // 작업 디스패치
        if let workItem = workItem {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: workItem)
        }
    }


    public func pushViewController(_ name: String, address: Int) {
        guard isRun else { return }
        print()
        print(" 🧲 pushViewController \(name) 🧲 address: \(address)")
        self.vcInfos.append(VCInfoClass(name, address: address))
    }

    public func popViewController(_ name: String, address: Int) {
        guard isRun else { return }
        print()
        print(" ✴️ popViewController \(name) ✴️ ")
        checkDeinit(name, address: address)
    }

    public func initObject(_ name: String) {
        guard isRun else { return }
        guard let vcInfo = vcInfos.last else { return }
        if let viewInfo = vcInfo.objects.first(where: { $0.name == name }) {
            viewInfo.count += 1
            print("add Object \(name) count: \(viewInfo.count)")
        }
        else {
            vcInfo.objects.append(.init(name: name))
            print("add Object \(name) count: 1")
        }

    }

    public func deinitObject(_ name: String) {
        guard isRun else { return }
        guard let vcInfo = vcInfos.last else { return }
        if let viewInfo = vcInfo.objects.first(where: { $0.name == name }) {
            viewInfo.count -= 1
            print("deinit Object \(name) count: \(viewInfo.count)")
        }
    }

    private func checkDeinit(_ name: String, address: Int) {
        guard isRun else { return }
        workItem?.cancel()
        workItem = nil
        var objects = [VCInfoClass.ObjectInfo]()
        var removeVi = [VCInfoClass]()
        for vi in self.vcInfos.reversed() {
            objects.append(contentsOf: vi.objects)
            removeVi.append(vi)
            if vi.vcName == name, vi.address == address { break }
        }
        let deadline = Double(objects.count) * 0.3
        DispatchQueue.main.asyncAfter(deadline: .now() + deadline) {
            print()
            print(" ⚠️ deinit checker start ⚠️")
            var list: [String] = [String]()
            list.reserveCapacity(objects.count)
            for vi in objects {
                if vi.count > 0 {
                    list.append("\t\(vi.name) count: \(vi.count)")
                }
            }
            self.vcInfos.removeAll(where: { removeVi.contains($0) })
            if list.count > 0 {
                let string = """
                ------ Warning -------
                👊🏻  \(name)  👊🏻
                💣 deinit Check Fail -----
                ⬇️ 해제 되지 않은 메모리를 빼주세요 -----
                --------------------------------

                \(list.joined(separator: "\n"))
                
                -------------------------------
                """
                print(string)
                self.makeView(value: string)
            }
            else {
                self.checkOK(name)
            }
            print(" ⚠️ deinit checker end ⚠️")
            print()
        }
    }
}

```
