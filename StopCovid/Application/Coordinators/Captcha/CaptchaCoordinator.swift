//
//  CaptchaCoordinator.swift
//  StopCovid
//
//  Created by Nicolas on 05/06/2020.
//  Copyright © 2020 Lunabee Studio. All rights reserved.
//

import UIKit

final class CaptchaCoordinator: Coordinator {

    weak var parent: Coordinator?
    var childCoordinators: [Coordinator] = []
    
    private weak var presentingController: UIViewController?
    private weak var navigationController: UINavigationController?
    private let initialCaptcha: Captcha
    private let didEnterCaptcha: (_ id: String, _ answer: String) -> ()
    private let didCancelCaptcha: () -> ()

    
    init(presentingController: UIViewController?, parent: Coordinator, captcha: Captcha, didEnterCaptcha: @escaping (_ id: String, _ answer: String) -> (), didCancelCaptcha: @escaping () -> ()) {
        self.presentingController = presentingController
        self.parent = parent
        self.initialCaptcha = captcha
        self.didEnterCaptcha = didEnterCaptcha
        self.didCancelCaptcha = didCancelCaptcha
        start()
    }
    
    private func start() {
        let controller: UIViewController = CaptchaViewController(captcha: initialCaptcha, didEnterCaptcha: { [weak self] id, answer in
            self?.didEnterCaptcha(id, answer)
        }) { [weak self] in
            self?.didCancelCaptcha()
            self?.didDeinit()
        }
        let navigationController: CVNavigationController = CVNavigationController(rootViewController: controller)
        self.navigationController = navigationController
        presentingController?.present(navigationController, animated: true, completion: nil)
    }
    
}
