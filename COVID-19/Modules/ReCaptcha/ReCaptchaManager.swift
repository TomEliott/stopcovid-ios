// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  ReCaptchaManager.swift
//  STOP-COVID
//
//  Created by Lunabee Studio / Date - 12/05/2020 - for the STOP-COVID project.
//


import UIKit
import WebKit
import ReCaptcha
import PKHUD

final class ReCaptchaManager: NSObject {

    static let shared: ReCaptchaManager = ReCaptchaManager()
    var recaptcha: ReCaptcha?
    var controller: ReCaptchaController?
    
    func validate(on viewController: UIViewController, completion: @escaping (_ token: String?) -> ()) {
        let controller: ReCaptchaController = ReCaptchaController { [weak self] in
            self?.reset()
        }
        recaptcha = try? ReCaptcha(apiKey: "Fake",
                                   baseURL: URL(string: "https:"))
        HUD.show(.progress)
        recaptcha?.configureWebView { webView in
            HUD.hide()
            controller.modalPresentationStyle = .overFullScreen
            controller.setupWebView(webView)
            controller.present(on: viewController)
        }
        recaptcha?.validate(on: controller.containerView) { result in
            HUD.hide()
            do {
                let token: String = try result.dematerialize()
                completion(token)
            } catch {
                print(error)
                completion(nil)
            }
            controller.dismiss()
            self.reset()
        }
    }
    
    private func reset() {
        // Needed for the open controller to be deallocated.
        controller = nil
        recaptcha = nil
    }
    
}
