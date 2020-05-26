// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  ProximityController.swift
//  STOP-COVID
//
//  Created by Lunabee Studio / Date - 09/04/2020 - for the STOP-COVID project.
//

import UIKit
import PKHUD
import RobertSDK

final class ProximityController: CVTableViewController {
    
    var canActivateProximity: Bool = false
    var didTouchManageData: (() -> ())?
    var didTouchPrivacy: (() -> ())?
    var didTouchAbout: (() -> ())?
    var deinitBlock: (() -> ())?
    
    private var popRecognizer: InteractivePopGestureRecognizer?
    private var initialContentOffset: CGFloat?
    private var isActivated: Bool { canActivateProximity && RBManager.shared.isProximityActivated }
    private var isChangingState: Bool = false
    
    init(didTouchAbout: (() -> ())?, didTouchManageData: (() -> ())?, didTouchPrivacy: (() -> ())?, deinitBlock: (() -> ())?) {
        self.didTouchAbout = didTouchAbout
        self.didTouchManageData = didTouchManageData
        self.didTouchPrivacy = didTouchPrivacy
        self.deinitBlock = deinitBlock
        super.init(style: .plain)
    }
    
    required init?(coder: NSCoder) {
        fatalError("Must use the other init method")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
        initBottomMessageContainer()
        addObserver()
        reloadUI()
        updateAuthorizationsState()
        setInteractiveRecognizer()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        initInitialContentOffset()
    }
    
    deinit {
        removeObservers()
        deinitBlock?()
    }
    
    private func initInitialContentOffset() {
        if initialContentOffset == nil {
            initialContentOffset = tableView.contentOffset.y
        }
    }
    
    private func updateTitle() {
        title = isActivated ? "common.bravo".localized : "common.warning".localized
        navigationChildController?.updateTitle(title)
    }
    
    private func updateAuthorizationsState() {
        NotificationsManager.shared.areNotificationsAuthorized { notificationsAuthorized in
            BluetoothAuthorizationManager.shared.isBluetoothAuthorized { bluetoothAuthorized in
                let messageFont: UIFont? = Appearance.BottomMessage.font
                let messageTextColor: UIColor = .black
                let messageBackgroundColor: UIColor = Asset.Colors.info.color
                if !notificationsAuthorized && !bluetoothAuthorized {
                    self.bottomMessageContainerController?.updateMessage(text: "proximityController.error.noNotificationsOrBluetooth".localized,
                                                                         font: messageFont,
                                                                         textColor: messageTextColor,
                                                                         backgroundColor: messageBackgroundColor,
                                                                         actionHint: "accessibility.hint.proximity.alert.touchToGoToSettings.ios".localized)
                } else if !notificationsAuthorized {
                    self.bottomMessageContainerController?.updateMessage(text: "proximityController.error.noNotifications".localized,
                                                                         font: messageFont,
                                                                         textColor: messageTextColor,
                                                                         backgroundColor: messageBackgroundColor,
                                                                         actionHint: "accessibility.hint.proximity.alert.touchToGoToSettings.ios".localized)
                } else if !bluetoothAuthorized {
                    self.bottomMessageContainerController?.updateMessage(text: "proximityController.error.noBluetooth".localized,
                                                                         font: messageFont,
                                                                         textColor: messageTextColor,
                                                                         backgroundColor: messageBackgroundColor,
                                                                         actionHint: "accessibility.hint.proximity.alert.touchToGoToSettings.ios".localized)
                } else if !RBManager.shared.isProximityActivated {
                    self.bottomMessageContainerController?.updateMessage(text: "proximityController.error.activateProximity".localized,
                                                                         font: messageFont,
                                                                         textColor: messageTextColor,
                                                                         backgroundColor: messageBackgroundColor)
                } else {
                    self.bottomMessageContainerController?.updateMessage()
                }
                self.canActivateProximity = notificationsAuthorized && bluetoothAuthorized
                self.reloadUI(animated: true)
            }
        }
    }
    
    override func createRows() -> [CVRow] {
        var rows: [CVRow] = []
        let titleRow: CVRow = CVRow.titleRow(title: title) { [weak self] cell in
            self?.navigationChildController?.updateLabel(titleLabel: cell.cvTitleLabel, containerView: cell)
        }
        rows.append(titleRow)
        let subtitleRow: CVRow = CVRow(title: isActivated ? "proximityController.switch.subtitle.activated".localized : "proximityController.switch.subtitle.deactivated".localized,
                                   xibName: .textCell,
                                   theme: CVRow.Theme(topInset: 0.0,
                                                      bottomInset: 20.0,
                                                      textAlignment: .left,
                                                      titleFont: { Appearance.Cell.Text.standardBigFont },
                                                      separatorLeftInset: nil))
        rows.append(subtitleRow)
        let imageRow: CVRow = CVRow(image: isActivated ? Asset.Images.proximity.image : Asset.Images.proximityOff.image,
                                    xibName: .onboardingImageCell,
                                    theme: CVRow.Theme(imageRatio: Appearance.Cell.Image.defaultRatio,
                                                       separatorLeftInset: nil))
        rows.append(imageRow)
        let activationButtonRow: CVRow = CVRow(title: isActivated ? "proximityController.button.deactivateProximity".localized : "proximityController.button.activateProximity".localized,
                                       xibName: .buttonCell,
                                       theme: CVRow.Theme(topInset: 20.0, bottomInset: 20.0, buttonStyle: isActivated ? .secondary : .primary),
                                       enabled: canActivateProximity,
                                       selectionAction: { [weak self] in
                                        guard let self = self else { return }
            self.didChangeSwitchValue(isOn: !self.isActivated)
        })
        rows.append(activationButtonRow)
        let textRow: CVRow = CVRow(subtitle: isActivated ? "proximityController.mainMessage.subtitle.on".localized : "proximityController.mainMessage.subtitle.off".localized,
                                   xibName: .textCell,
                                   theme: CVRow.Theme(topInset: 0.0, bottomInset: 20.0, textAlignment: .left, separatorLeftInset: Appearance.Cell.leftMargin))
        rows.append(textRow)
        let manageDataRow: CVRow = CVRow(title: "proximityController.manageData".localized,
                                         image: Asset.Images.manageData.image,
                                         xibName: .standardCell,
                                         theme: CVRow.Theme(topInset: 15.0,
                                                            bottomInset: 15.0,
                                                            textAlignment: .left,
                                                            titleFont: { Appearance.Cell.Text.standardFont },
                                                            titleColor: Asset.Colors.tint.color,
                                                            imageTintColor: Appearance.Cell.Image.tintColor,
                                                            imageSize: Appearance.Cell.Image.size,
                                                            separatorLeftInset: Appearance.Cell.leftMargin), selectionAction: { [weak self] in
                                        self?.didTouchManageData?()
                                    })
        rows.append(manageDataRow)
        let privacyRow: CVRow = CVRow(title: "privacyController.tabBar.title".localized,
                                      image: Asset.Images.privacy.image,
                                      xibName: .standardCell,
                                      theme: CVRow.Theme(topInset: 15.0,
                                                         bottomInset: 15.0,
                                                         textAlignment: .left,
                                                         titleFont: { Appearance.Cell.Text.standardFont },
                                                         titleColor: Asset.Colors.tint.color,
                                                         imageTintColor: Appearance.Cell.Image.tintColor,
                                                         imageSize: Appearance.Cell.Image.size,
                                                         separatorLeftInset: 0.0), selectionAction: { [weak self] in
                                                            self?.didTouchPrivacy?()
                                })
        rows.append(privacyRow)
        rows.append(.empty)
        return rows
    }
    
    override func reloadUI(animated: Bool = false) {
        tableView.contentInset.bottom = bottomMessageContainerController?.messageHeight ?? 0.0
        updateTitle()
        super.reloadUI(animated: animated)
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if canActivateProximity && RBManager.shared.isProximityActivated {
            let distance: CGFloat = abs((initialContentOffset ?? 0.0) - tableView.contentOffset.y) + (tableView.tableFooterView?.frame.height ?? 0.0)
            if tableView.contentInset.bottom != 0.0 && distance < tableView.contentInset.bottom {
                tableView.contentInset.bottom = 0.0
            }
        }
        navigationChildController?.scrollViewDidScroll(scrollView)
    }
    
    private func initUI() {
        tableView.contentInset.top = navigationChildController?.navigationBarHeight ?? 0.0
        tableView.tableFooterView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 0.0, height: 20.0))
        tableView.estimatedRowHeight = UITableView.automaticDimension
        tableView.rowHeight = UITableView.automaticDimension
        tableView.backgroundColor = Appearance.Controller.backgroundColor
        tableView.showsVerticalScrollIndicator = false
        navigationController?.setNavigationBarHidden(true, animated: false)
        navigationChildController?.updateRightBarButtonItem(UIBarButtonItem(title: "common.about".localized, style: .plain, target: self, action: #selector(didTouchAboutButton)))
    }
    
    private func initBottomMessageContainer() {
        bottomMessageContainerController?.messageDidTouch = { [weak self] in
            if self?.canActivateProximity == true {
                self?.didChangeSwitchValue(isOn: true)
            } else {
                UIApplication.shared.openSettings()
            }
        }
    }
    
    private func addObserver() {
        LocalizationsManager.shared.addObserver(self)
        NotificationCenter.default.addObserver(self, selector: #selector(appWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    private func removeObservers() {
        LocalizationsManager.shared.removeObserver(self)
        NotificationCenter.default.removeObserver(self)
    }
    
    private func didChangeSwitchValue(isOn: Bool) {
        guard !isChangingState else { return }
        isChangingState = true
        if isOn {
            if RBManager.shared.isRegistered {
                processRegistrationDone()
                isChangingState = false
            } else {
                ReCaptchaManager.shared.validate(on: self) { token in
                    guard let token = token else {
                        self.showAlert(title: "common.error".localized,
                                       message: "proximityService.error.captchaError".localized,
                                       okTitle: "common.ok".localized)
                        self.isChangingState = false
                        return
                    }
                    HUD.show(.progress)
                    RBManager.shared.register(token: token) { error in
                        HUD.hide()
                        self.isChangingState = false
                        if let error = error {
                            self.showAlert(title: "common.error".localized,
                                           message: error.localizedDescription,
                                           okTitle: "common.ok".localized)
                        } else {
                            self.processRegistrationDone()
                        }
                    }
                }
            }
        } else {
            RBManager.shared.isProximityActivated = false
            updateAuthorizationsState()
            RBManager.shared.stopProximityDetection()
            isChangingState = false
        }
    }
    
    private func processRegistrationDone() {
        RBManager.shared.isProximityActivated = true
        updateAuthorizationsState()
        RBManager.shared.startProximityDetection()
    }
    
    @objc private func didTouchAboutButton() {
        didTouchAbout?()
    }
    
    @objc private func appWillEnterForeground() {
        updateAuthorizationsState()
    }
    
    private func setInteractiveRecognizer() {
        guard let navigationController = navigationController else { return }
        popRecognizer = InteractivePopGestureRecognizer(controller: navigationController)
        navigationController.interactivePopGestureRecognizer?.delegate = popRecognizer
    }

}

extension ProximityController: LocalizationsChangesObserver {
    
    func localizationsChanged() {
        updateTitle()
        reloadUI()
    }
    
}
