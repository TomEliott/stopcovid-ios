// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  CVNavigationChildController.swift
//  STOP-COVID
//
//  Created by Lunabee Studio / Date - 09/04/2020 - for the STOP-COVID project.
//

import UIKit

final class CVNavigationChildController: UIViewController {
    
    var navigationBarHeight: CGFloat { navigationBar.frame.height }
    
    @IBOutlet private var navigationBarBackgroundView: UIVisualEffectView!
    @IBOutlet private var navigationBar: UINavigationBar!
    @IBOutlet private var containerView: UIView!
    
    @IBOutlet private var fakeNavigationBar: UINavigationBar!
    @IBOutlet private var fakeNavigationItem: UINavigationItem!
    
    weak var titleLabel: UILabel?
    private weak var titleLabelContainerView: UIView?
    private var embeddedController: UIViewController?
    private var titleLabelContainerViewIntialY: CGFloat?
    private var initialTitleLabelMinY: CGFloat?

    class func controller(_ embeddedController: UIViewController) -> UIViewController {
        let containerController: CVNavigationChildController = StoryboardScene.CVNavigationChild.cvNavigationChildController.instantiate()
        containerController.embeddedController = embeddedController
        return containerController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initNavigationBar()
        setupEmbeddedController()
    }
    
    func updateTitle(_ title: String?) {
        navigationBar.topItem?.title = title
    }
    
    func updateLabel(titleLabel: UILabel?, containerView: UIView?) {
        self.titleLabel = titleLabel
        self.titleLabelContainerView = containerView
        setupNavigationTitle()
    }
    
    func updateLeftBarButtonItem(_ barButtonItem: UIBarButtonItem) {
        fakeNavigationItem.leftBarButtonItem = barButtonItem
    }
    
    func updateRightBarButtonItem(_ barButtonItem: UIBarButtonItem) {
        fakeNavigationItem.rightBarButtonItem = barButtonItem
    }
    
    private func initNavigationBar() {
        navigationBar.isAccessibilityElement = false
        navigationBar.accessibilityElementsHidden = true
        navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationBar.titleTextAttributes = [.font: Appearance.NavigationBar.titleFont]
        updateNavigationBarAlpha(0.0)
        fakeNavigationBar.setBackgroundImage(UIImage(), for: .default)
        fakeNavigationBar.shadowImage = UIImage()
        fakeNavigationBar.tintColor = Asset.Colors.tint.color
    }
    
    private func setupEmbeddedController() {
        guard let controller = embeddedController else { return }
        addChildViewController(controller, containerView: containerView)
    }
    
    private func updateNavigationBarAlpha(_ alpha: CGFloat) {
        navigationBar.alpha = alpha
        navigationBarBackgroundView.alpha = alpha
        titleLabel?.alpha = 1.0 - alpha
    }

    private func setupNavigationTitle() {
        guard titleLabelContainerViewIntialY == nil else { return }
        titleLabelContainerViewIntialY = titleLabelContainerView?.frame.minY
        guard let titleLabel = titleLabel else { return }
        let frame: CGRect = view.convert(titleLabel.frame, from: titleLabel.superview)
        initialTitleLabelMinY = frame.midY - 40.0
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let titleLabel = titleLabel else { return }
        guard titleLabelContainerView?.frame.minY == titleLabelContainerViewIntialY else { return }
        let navigationBarFrame: CGRect = navigationBar.frame
        let titleFrame: CGRect = view.convert(titleLabel.frame, from: titleLabel.superview)
        let distance: CGFloat = titleFrame.midY - navigationBarFrame.maxY
        let alpha: CGFloat = 1.0 - max(min(distance / ((initialTitleLabelMinY ?? 0.0) - navigationBarFrame.maxY), 1.0), 0.0)
        updateNavigationBarAlpha(alpha)
    }
    
}

extension UIViewController {
    
    var navigationChildController: CVNavigationChildController? {
        var parentController: UIViewController? = self
        while let controller = parentController?.parent {
            parentController = controller
            if parentController is CVNavigationChildController {
                break
            }
        }
        return parentController as? CVNavigationChildController
    }
    
}
