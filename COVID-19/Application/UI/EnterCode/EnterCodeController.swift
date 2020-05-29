// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  EnterCodeController.swift
//  STOP-COVID
//
//  Created by Lunabee Studio / Date - 09/04/2020 - for the STOP-COVID project.
//

import UIKit

final class EnterCodeController: CVTableViewController {
    
    weak var textField: UITextField?
    var code: String?
    
    private let didEnterCode: (_ code: String?) -> ()
    private let deinitBlock: () -> ()
    
    init(didEnterCode: @escaping (_ code: String?) -> (), deinitBlock: @escaping () -> ()) {
        self.didEnterCode = didEnterCode
        self.deinitBlock = deinitBlock
        super.init(style: .plain)
    }
    
    required init?(coder: NSCoder) {
        fatalError("Must use standard init() method")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "sickController.button.tap".localized
        initUI()
        reloadUI()
        LocalizationsManager.shared.addObserver(self)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        textField?.becomeFirstResponder()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        textField?.resignFirstResponder()
    }
    
    deinit {
        LocalizationsManager.shared.removeObserver(self)
        deinitBlock()
    }
    
    override func createRows() -> [CVRow] {
        let titleRow: CVRow = CVRow(title: "enterCodeController.title".localized,
                                   xibName: .textCell,
                                   theme: CVRow.Theme(topInset: 40.0, bottomInset: 30.0, textAlignment: .center, titleFont: { Appearance.Controller.titleFont }))
        let textRow: CVRow = CVRow(title: "enterCodeController.mainMessage.title".localized,
                                   subtitle: "enterCodeController.mainMessage.subtitle".localized,
                                   xibName: .textCell,
                                   theme: CVRow.Theme(topInset: 0.0))
        let textFieldRow: CVRow = CVRow(placeholder: "enterCodeController.textField.placeholder".localized,
                                        xibName: .textFieldCell,
                                        theme: CVRow.Theme(topInset: 30.0,
                                                           placeholderColor: .lightGray,
                                                           separatorLeftInset: Appearance.Cell.leftMargin,
                                                           separatorRightInset: Appearance.Cell.leftMargin),
                                        textFieldKeyboardType: .default,
                                        willDisplay: { [weak self] cell in
                                            self?.textField = (cell as? TextFieldCell)?.cvTextField
        }, valueChanged: { [weak self] value in
            guard let code = value as? String else { return }
            self?.code = code
        })
        let buttonRow: CVRow = CVRow(title: "enterCodeController.button.validate".localized,
                                     xibName: .buttonCell,
                                     theme: CVRow.Theme(topInset: 40.0),
                                     selectionAction: { [weak self] in
                                        self?.didTouchValidate()
        })
        return [titleRow, textRow, textFieldRow, buttonRow]
    }
    
    private func initUI() {
        tableView.tableFooterView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 0.0, height: 20.0))
        tableView.estimatedRowHeight = UITableView.automaticDimension
        tableView.rowHeight = UITableView.automaticDimension
        tableView.backgroundColor = Appearance.Controller.backgroundColor
        tableView.showsVerticalScrollIndicator = false
        navigationController?.navigationBar.titleTextAttributes = [.font: Appearance.NavigationBar.titleFont]
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "common.close".localized, style: .plain, target: self, action: #selector(didTouchCloseButton))
    }
    
    private func didTouchValidate() {
        if let code = code, ServerConstant.acceptedReportCodeLength.contains(code.count) {
            tableView.endEditing(true)
            didEnterCode(code)
        } else {
            showAlert(title: "enterCodeController.alert.invalidCode.title".localized,
                      message: "enterCodeController.alert.invalidCode.message".localized,
                      okTitle: "common.ok".localized)
        }
    }
    
    @objc private func didTouchCloseButton() {
        dismiss(animated: true, completion: nil)
    }

}

extension EnterCodeController: LocalizationsChangesObserver {
    
    func localizationsChanged() {
        reloadUI()
    }
    
}

