// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  OnboardingCoordinator.swift
//  STOP-COVID
//
//  Created by Lunabee Studio / Date - 08/04/2020 - for the STOP-COVID project.
//

import UIKit

final class OnboardingCoordinator: WindowedCoordinator {
    
    weak var parent: Coordinator?
    var childCoordinators: [Coordinator]
    var window: UIWindow!
    
    private weak var navigationController: UINavigationController?
    private let onboardingDidEnd: () -> ()
    
    init(parent: Coordinator, onboardingDidEnd: @escaping () -> ()) {
        self.parent = parent
        self.childCoordinators = []
        self.onboardingDidEnd = onboardingDidEnd
        start()
    }
    
    private func start() {
        let controller: UIViewController = OnboardingWelcomeController(didContinue: { [weak self] in
            self?.didTouchHowDoesItWork()
        }, deinitBlock: { [weak self] in
            self?.didDeinit()
        })
        let navController: CVNavigationController = CVNavigationController(rootViewController: CVNavigationChildController.controller(controller))
        navigationController = navController
        createWindow(for: BottomButtonContainerController.controller(navController, accessibilityHint: "accessibility.hint.onboarding.bottomButton".localized))
    }
    
}

// MARK: - Flow management -
extension OnboardingCoordinator {
    
    private func didTouchHowDoesItWork() {
        let controller: UIViewController = CVNavigationChildController.controller(OnboardingExplanationsController(didContinue: { [weak self] in
            self?.didTouchPrivacy()
        }))
        navigationController?.show(controller, sender: nil)
    }
    
    private func didTouchPrivacy() {
        let controller: UIViewController = CVNavigationChildController.controller(OnboardingPrivacyController(didContinue:  { [weak self] in
            self?.didTouchAcceptPrivacy()
        }))
        navigationController?.show(controller, sender: nil)
    }
    
    private func didTouchAcceptPrivacy() {
        let controller: UIViewController = CVNavigationChildController.controller(OnboardingProximityController(didContinue:  { [weak self] in
            self?.didProcessAllowProximity()
        }))
        navigationController?.show(controller, sender: nil)
    }
    
    private func didProcessAllowProximity() {
        let controller: UIViewController = CVNavigationChildController.controller(OnboardingBeAwareController(didContinue:  { [weak self] in
            self?.didProcessAllowNotifications()
        }))
        navigationController?.show(controller, sender: nil)
    }
    
    private func didProcessAllowNotifications() {
        let controller: UIViewController = CVNavigationChildController.controller(OnboardingGesturesController(didContinue:  { [weak self] in
            self?.didTouchNoted()
        }))
        navigationController?.show(controller, sender: nil)
    }
    
    private func didTouchNoted() {
        onboardingDidEnd()
    }
    
}
