//
//  DeinitManager.swift
//  DeinitManager
//
//  Created by 박길호on 12/30/24.
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

@MainActor
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
