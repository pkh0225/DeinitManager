    //
//  DeinitManager.swift
//  ssg
//
//  Created by pkh on 2018. 7. 11..
//  Copyright © 2018년 emart. All rights reserved.
//

import UIKit

public protocol DeinitChecker: AnyObject {
    var deinitNotifier: DeinitNotifier? { get set }
}

extension DeinitChecker {
    public func setDeinitNotifier() {
        guard DeinitManager.shared.isRun else {
            deinitNotifier = nil
            return
        }
        guard deinitNotifier == nil else { return }

        let name = String(describing: type(of: self))
        DeinitManager.shared.initObject(name)
        self.deinitNotifier = DeinitNotifier() {
            DeinitManager.shared.deinitObject(name)
        }
    }
}

public final class DeinitNotifier {
    private let onDeinitNotifier: () -> Void

    public init(onDeinitNotifier: @escaping () -> Void) {
        self.onDeinitNotifier = onDeinitNotifier
    }

    deinit {
        onDeinitNotifier()
    }
}

extension DeinitChecker where Self: UIViewController {
    public func setDeinitNotifier() {
        guard DeinitManager.shared.isRun else {
            deinitNotifier = nil
            return
        }
        guard deinitNotifier == nil else { return }
        let navigationController = self.navigationController
        let name = String(describing: type(of: self))

        if navigationController?.viewControllers.last == self {
            let point = unsafeBitCast(self, to: Int.self)
            DeinitManager.shared.pushViewController(name, address: point)
            self.deinitNotifier = DeinitNotifier() {
                DeinitManager.shared.popViewController(name, address: point)
            }
        }
        else {
            DeinitManager.shared.initObject(name)
            self.deinitNotifier = DeinitNotifier() {
                DeinitManager.shared.deinitObject(name)
            }
        }
    }
}


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

//MARK: - UI Result
extension DeinitManager {
    func keyWindow() -> UIWindow? {
        var window: UIWindow?
        if #available(iOS 13.0, *) {
            window = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first
        } else {
            window = UIApplication.shared.keyWindow
        }
        return window
    }

    private func checkOK(_ className : String) {
        DispatchQueue.main.async {
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
                wrapperView.centerYAnchor.constraint(equalTo: keyWindow.centerYAnchor, constant: keyWindow.safeAreaInsets.top),

                // StackView의 마진 설정 (컨테이너와의 거리)
                stackView.topAnchor.constraint(equalTo: wrapperView.topAnchor, constant: 20),
                stackView.leadingAnchor.constraint(equalTo: wrapperView.leadingAnchor, constant: 20),
                stackView.trailingAnchor.constraint(equalTo: wrapperView.trailingAnchor, constant: -20),
                stackView.bottomAnchor.constraint(equalTo: wrapperView.bottomAnchor, constant: -20)
            ])

            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                wrapperView.removeFromSuperview()
            }
        }
    }

    private func makeView(value: String) {
        DispatchQueue.main.async {
            guard let keyWindow = self.keyWindow() else { return }
            let view: UIView = UIView()
            view.clipsToBounds = true
            view.translatesAutoresizingMaskIntoConstraints = false
            view.tag = 987654321
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
            btn.backgroundColor = .green
            btn.setTitle("닫기", for: .normal)
            btn.setTitleColor(.black, for: .normal)
            btn.addTarget(self, action: #selector(self.onClose(btn:)), for: .touchUpInside)


            let btn2: UIButton = UIButton()
            btn2.translatesAutoresizingMaskIntoConstraints = false
            btn2.backgroundColor = .blue
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
    }

    @objc func onClose(btn: UIButton) {
        guard let keyWindow = self.keyWindow() else { return }
        keyWindow.viewWithTag(987654321)?.removeFromSuperview()
    }

    @objc func onReset(btn: UIButton) {
        guard let keyWindow = self.keyWindow() else { return }
        keyWindow.viewWithTag(987654321)?.removeFromSuperview()
        self.vcInfos.removeAll()
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
