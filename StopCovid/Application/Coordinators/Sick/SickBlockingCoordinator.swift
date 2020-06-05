// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  SickBlockingCoordinator.swift
//  STOP-COVID
//
//  Created by Lunabee Studio / Date - 21/05/2020 - for the STOP-COVID project.
//


import UIKit
import RobertSDK

final class SickBlockingCoordinator: WindowedCoordinator {

    weak var parent: Coordinator?
    var childCoordinators: [Coordinator]
    var window: UIWindow!
    
    private weak var currentController: UIViewController?
    
    init(parent: Coordinator) {
        self.parent = parent
        self.childCoordinators = []
        start()
    }
    
    private func start() {
        let controller: UIViewController = CVNavigationChildController.controller(SickController(didTouchAbout: { [weak self] in
            self?.didTouchAbout()
        }, didTouchFlash: {}, didTouchTap: {}, didTouchReadMore: {}))
        currentController = controller
        createWindow(for: controller)
    }
    
    private func didTouchAbout() {
        let coordinator: AboutCoordinator = AboutCoordinator(presentingController: currentController, parent: self)
        addChild(coordinator: coordinator)
    }
    
}
