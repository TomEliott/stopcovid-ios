// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  UIViewController+Extension.swift
//  STOP-COVID
//
//  Created by Lunabee Studio / Date - 08/04/2020 - for the STOP-COVID project.
//

import UIKit
import PKHUD

extension UIViewController {
    
    var topPresentedController: UIViewController {
        var presentedController: UIViewController = self
        while let controller = presentedController.presentedViewController {
            presentedController = controller
        }
        return presentedController
    }
    
    func addChildViewController(_ childController: UIViewController, containerView: UIView) {
        addChild(childController)
        let childView: UIView = childController.view
        containerView.addConstrainedSubview(childView)
        childController.didMove(toParent: self)
    }
    
    func showAlert(title: String? = nil, message: String? = nil, okTitle: String, isOkDestructive: Bool = false, cancelTitle: String? = nil, handler: (() -> ())? = nil) {
        let alertController: UIAlertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: okTitle, style: isOkDestructive ? .destructive : .default, handler: { _ in handler?() }))
        if let cancelTitle = cancelTitle {
            alertController.addAction(UIAlertAction(title: cancelTitle, style: .cancel))
        }
        present(alertController, animated: true, completion: nil)
    }
    
    func showFlash(success: Bool = true) {
        HUD.flash(success ? .success : .error, onView: self.view.window, delay: 0.8)
    }
    
    func showTextFieldAlert(_ title: String? = nil, message: String? = nil, textFieldPlaceHolder: String? = nil, textFieldDefaultValue: String? = nil, completion: @escaping (_ newValue: String) -> Void) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addTextField(configurationHandler: { textField in
            textField.text = textFieldDefaultValue
            textField.placeholder = textFieldPlaceHolder
        })
        alert.addAction(UIAlertAction(title: "common.ok".localized, style: .default, handler: { (_) -> Void in
            let textField = alert.textFields![0] as UITextField
            completion(textField.text ?? textFieldDefaultValue ?? "")
        }))
        alert.addAction(UIAlertAction(title: "common.cancel".localized, style: UIAlertAction.Style.cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
}
