// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  SymptomsOriginCoordinator.swift
//  STOP-COVID
//
//  Created by Lunabee Studio / Date - 04/05/2020 - for the STOP-COVID project.
//

import UIKit

final class SymptomsOriginCoordinator: Coordinator {

    weak var parent: Coordinator?
    var childCoordinators: [Coordinator] = []
    
    private weak var navigationController: UINavigationController?
    
    init(navigationController: UINavigationController?, parent: Coordinator, symptomsParams: SymptomsDeclarationParams) {
        self.navigationController = navigationController
        self.parent = parent
        start(symptomsParams: symptomsParams)
    }
    
    private func start(symptomsParams: SymptomsDeclarationParams) {
        navigationController?.pushViewController(SymptomsOriginController(symptomsParams: symptomsParams, didChooseDateBlock: { [weak self] symptomsParams in
            self?.showSendHistory(symptomsParams: symptomsParams)
        }, deinitBlock: { [weak self] in
            self?.didDeinit()
        }), animated: true)
    }
    
    private func showSendHistory(symptomsParams: SymptomsDeclarationParams) {
        let controller: SendHistoryController = SendHistoryController(symptomsParams: symptomsParams) { [weak self] in
            self?.navigationController?.dismiss(animated: true, completion: nil)
        }
        navigationController?.pushViewController(BottomButtonContainerController.controller(controller), animated: true)
    }
    
}
