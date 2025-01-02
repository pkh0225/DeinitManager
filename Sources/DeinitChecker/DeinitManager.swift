//
//  DeinitManager.swift
//  DeinitManager
//
//  Created by 박길호on 12/30/24.
//

import UIKit

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

    static public let shared: DeinitManager = { return DeinitManager() }()
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

    @MainActor
    public func checkPopViewController(_ name: String, address: Int) {
        guard isRun else { return }
        guard self.vcInfos.last?.vcName == name, self.vcInfos.last?.address == address else { return }
//        print("checkPopViewController name: \(name), address: \(address)")
        // 이전 작업 취소 (있다면)
        workItem?.cancel()

        makeCheckDisplayView()
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
                DispatchQueue.main.async {
                    self.makeView(value: string)
                }
            }
        }

        // 작업 디스패치
        if let workItem = workItem {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: workItem)
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

//MARK: - UI Result
@MainActor
extension DeinitManager {
    private static let resultViewTag: Int = 987654321
    private static let checkDisplayViewTag: Int = 987654322

    func keyWindow() -> UIWindow? {
        var window: UIWindow?
        if #available(iOS 13.0, *) {
            window = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first
        } else {
            window = UIApplication.shared.keyWindow
        }
        return window
    }

    final class CheckLabel: UILabel {
        private var timer: Timer?
        private var textData = ["Memory Checking .",
                        "Memory Checking ..",
                        "Memory Checking ..."]
        private var textIndex: Int = 0

        static func RemoveCheckLabel(from: UIView) {
            Self.stopCheckLabel(from: from)
            from.viewWithTag(DeinitManager.checkDisplayViewTag)?.removeFromSuperview()
        }

        static func stopCheckLabel(from: UIView) {
            (from.viewWithTag(DeinitManager.checkDisplayViewTag) as? CheckLabel)?.removeTimer()
        }

        override init(frame: CGRect) {
            super.init(frame: frame)
            self.translatesAutoresizingMaskIntoConstraints = false
            self.isUserInteractionEnabled = true // 메모리 체크 중 일때 다른 액션을 막기 위해서...
            self.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.5)
            self.textColor = .white
            self.font = UIFont.systemFont(ofSize: 20)
            self.textAlignment = .center
            self.numberOfLines = 1
            self.text = textData[0]
            self.tag = DeinitManager.checkDisplayViewTag

            timer = Timer.scheduledTimer(timeInterval: 0.3,
                                         target: self,
                                         selector: #selector(self.updateText),
                                         userInfo: nil,
                                         repeats: true)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        func removeTimer() {
            self.text = nil
            self.timer?.invalidate()
            self.timer = nil
        }

        @objc private  func updateText() {
            if self.superview == nil {
                removeTimer()
                return
            }
            if textIndex >= textData.count - 1 {
                textIndex = -1
            }
            let text = textData[textIndex + 1]
            self.text = text
            textIndex += 1
        }
    }

    func makeCheckDisplayView() {
        guard let keywindow = keyWindow() else { return }

        let label = CheckLabel(frame: .zero)
        keywindow.addSubview(label)

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: keywindow.topAnchor, constant: 0),
            label.leadingAnchor.constraint(equalTo: keywindow.leadingAnchor, constant: 0),
            label.trailingAnchor.constraint(equalTo: keywindow.trailingAnchor, constant: 0),
            label.bottomAnchor.constraint(equalTo: keywindow.bottomAnchor, constant: 0)
        ])
    }

    private func checkOK(_ className : String) {
        guard let keyWindow = self.keyWindow() else { return }
        let string: String = "\n - \(className) -\n ---- deinitCheck OK  💯 ---- \n"
        print(string)

        let wrapperView = UIView()
        wrapperView.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.7)
        wrapperView.translatesAutoresizingMaskIntoConstraints = false
        wrapperView.layer.cornerRadius = 10
        keyWindow.addSubview(wrapperView)

        let titleLabel = UILabel()
        titleLabel.text = className
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        wrapperView.addSubview(titleLabel)

        let messageLabel = UILabel()
        messageLabel.text = "---- deinitCheck OK  💯 ----"
        messageLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        messageLabel.textColor = .white
        messageLabel.textAlignment = .center
        wrapperView.addSubview(messageLabel)

        let stackView = UIStackView(arrangedSubviews: [titleLabel, messageLabel])
        stackView.axis = .vertical
        stackView.spacing = 10
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.alignment = .fill
        stackView.distribution = .fill
        wrapperView.addSubview(stackView)

        NSLayoutConstraint.activate([
            wrapperView.centerXAnchor.constraint(equalTo: keyWindow.centerXAnchor),
            wrapperView.centerYAnchor.constraint(equalTo: keyWindow.centerYAnchor),

            // StackView의 마진 설정 (컨테이너와의 거리)
            stackView.topAnchor.constraint(equalTo: wrapperView.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: wrapperView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: wrapperView.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: wrapperView.bottomAnchor, constant: -20)
        ])

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            wrapperView.removeFromSuperview()
        }
        keyWindow.isUserInteractionEnabled = true
        self.removeResultView()
    }

    private func makeView(value: String) {
        guard let keyWindow = self.keyWindow() else { return }
        CheckLabel.stopCheckLabel(from: keyWindow)

        let view: UIView = UIView()
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        view.tag = Self.resultViewTag
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.black.cgColor
        keyWindow.addSubview(view)

        let textView: UITextView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.contentInset = UIEdgeInsets(top: 15, left: 10, bottom: 15, right: 10)
        textView.backgroundColor = .red
        textView.isEditable = false
        textView.font = UIFont.systemFont(ofSize: 14)
        textView.text = value

        let btn: UIButton = UIButton()
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.backgroundColor = #colorLiteral(red: 0.4666666687, green: 0.7647058964, blue: 0.2666666806, alpha: 1)
        btn.setTitle("닫기", for: .normal)
        btn.setTitleColor(.black, for: .normal)
        btn.addTarget(self, action: #selector(self.onClose(btn:)), for: .touchUpInside)

        let btn2: UIButton = UIButton()
        btn2.translatesAutoresizingMaskIntoConstraints = false
        btn2.backgroundColor = #colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1)
        btn2.setTitle("초기화", for: .normal)
        btn2.setTitleColor(.black, for: .normal)
        btn2.addTarget(self, action: #selector(self.onReset(btn:)), for: .touchUpInside)

        let stackViewHorizontal = UIStackView(arrangedSubviews: [btn, btn2])
        stackViewHorizontal.axis = .horizontal
        stackViewHorizontal.spacing = 0
        stackViewHorizontal.translatesAutoresizingMaskIntoConstraints = false
        stackViewHorizontal.alignment = .fill
        stackViewHorizontal.distribution = .fillEqually
        view.addSubview(stackViewHorizontal)

        let stackViewVertical = UIStackView(arrangedSubviews: [textView, stackViewHorizontal])
        stackViewVertical.axis = .vertical
        stackViewVertical.spacing = 0
        stackViewVertical.translatesAutoresizingMaskIntoConstraints = false
        stackViewVertical.alignment = .fill
        stackViewVertical.distribution = .fill

        view.addSubview(stackViewVertical)

        NSLayoutConstraint.activate([
            view.centerXAnchor.constraint(equalTo: keyWindow.centerXAnchor),
            view.centerYAnchor.constraint(equalTo: keyWindow.centerYAnchor),
            view.widthAnchor.constraint(equalTo: keyWindow.widthAnchor, multiplier: 0.8),
            view.heightAnchor.constraint(equalTo: keyWindow.heightAnchor, multiplier: 0.8),

            stackViewHorizontal.heightAnchor.constraint(equalToConstant: 50),

            stackViewVertical.topAnchor.constraint(equalTo: view.topAnchor, constant: 0),
            stackViewVertical.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
            stackViewVertical.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0),
            stackViewVertical.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0)
        ])
    }

    @objc func onClose(btn: UIButton) {
        removeResultView()
    }

    @objc func onReset(btn: UIButton) {
        self.vcInfos.removeAll()
        removeResultView()
    }

    func removeResultView() {
        guard let keyWindow = self.keyWindow() else { return }
        CheckLabel.RemoveCheckLabel(from: keyWindow)
        keyWindow.viewWithTag(Self.resultViewTag)?.removeFromSuperview()
        keyWindow.isUserInteractionEnabled = true
    }
}

// MARK: - Memory check
extension DeinitManager {
    func startMemoryReport() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            guard let keyWindow = self.keyWindow() else { return }
            guard self.isMemoryRepory == false else { return }

            self.memoryLabel = UILabel()
            self.memoryLabel?.translatesAutoresizingMaskIntoConstraints = false
            self.memoryLabel?.font = UIFont.systemFont(ofSize: 15)
            self.memoryLabel?.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.5)
            self.memoryLabel?.textColor = #colorLiteral(red: 0.9764705896, green: 0.850980401, blue: 0, alpha: 1)
            keyWindow.addSubview(self.memoryLabel!)
            NSLayoutConstraint.activate([
                self.memoryLabel!.trailingAnchor.constraint(equalTo: keyWindow.trailingAnchor, constant: 0),
                self.memoryLabel!.topAnchor.constraint(equalTo: keyWindow.safeAreaLayoutGuide.topAnchor, constant: 0)
            ])

            DispatchQueue.global().async {
                self.isMemoryRepory = true
                while self.isRun {
                    //                usleep(1000000) //will sleep for 1 second
                    usleep(500000) //will sleep for 0.5 seconds

                    let byteCount = self.memoryReport()
                    let bcf = ByteCountFormatter()
                    bcf.allowedUnits = [.useMB]
                    bcf.countStyle = .memory
//                    let string = bcf.string(fromByteCount: Int64(byteCount))
                    let string = bcf.string(fromByteCount: Int64(byteCount))

                    DispatchQueue.main.async {
                        self.memoryLabel?.text = " \(string) "
                    }
                }
                self.isMemoryRepory = false
                self.removeAll()
                DispatchQueue.main.async {
                    self.memoryLabel?.removeFromSuperview()
                }
            }
        }
    }

    func memoryReport() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout.size(ofValue: info) / MemoryLayout<integer_t>.size)
        let kerr = withUnsafeMutablePointer(to: &info) { infoPtr in
            return infoPtr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { (machPtr: UnsafeMutablePointer<integer_t>) in
                return task_info( mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), machPtr, &count)
            }
        }
        guard kerr == KERN_SUCCESS else { return 0 }

        return info.resident_size
    }
}

fileprivate extension UIViewController {
    private(set) static var isSwizzleMethodForViewWillDisappear: Bool = false

    static func enableSwizzleMethodForViewWillDisappear() {
        guard !isSwizzleMethodForViewWillDisappear else { return }
        isSwizzleMethodForViewWillDisappear = true
        swizzleMethodForViewWillDisappear()

    }

    static func disableSwizzleMethodForViewWillDisappear() {
        guard isSwizzleMethodForViewWillDisappear else { return }
        isSwizzleMethodForViewWillDisappear = false
        swizzleMethodForViewWillDisappear() // 다시 교환하여 원래 상태로 복구
    }

    static func swizzleMethodForViewWillDisappear() {
        let originalSelector = #selector(viewWillDisappear(_:))
        let swizzledSelector = #selector(swizzled_viewWillDisappear(_:))

        guard let originalMethod = class_getInstanceMethod(UIViewController.self, originalSelector),
              let swizzledMethod = class_getInstanceMethod(UIViewController.self, swizzledSelector) else {
            return
        }

        method_exchangeImplementations(originalMethod, swizzledMethod)
    }

    @objc private func swizzled_viewWillDisappear(_ animated: Bool) {
//        print("\(String(describing: Self.self)) will disappear!")
        swizzled_viewWillDisappear(animated)

        if self.isMovingFromParent {
            let name = String(describing: Self.self)
            let point = unsafeBitCast(self, to: Int.self)
            DeinitManager.shared.checkPopViewController(name, address: point)
        }
    }
}
