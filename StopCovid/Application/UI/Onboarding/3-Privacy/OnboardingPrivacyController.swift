// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  OnboardingPrivacyController.swift
//  STOP-COVID
//
//  Created by Lunabee Studio / Date - 08/04/2020 - for the STOP-COVID project.
//

import UIKit

final class OnboardingPrivacyController: OnboardingController {

    override var bottomButtonTitle: String { "onboarding.privacyController.accept".localized }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.separatorStyle = .singleLine
        PrivacyManager.shared.addObserver(self)
    }
    
    deinit {
        PrivacyManager.shared.removeObserver(self)
    }
    
    override func updateTitle() {
        title =  "onboarding.privacyController.title".localized
        super.updateTitle()
    }
    
    override func createCustomLeftBarButtonItem() -> UIBarButtonItem {
        return UIBarButtonItem.back(target: self, action: #selector(didTouchBackButton))
    }
    
    override func createRows() -> [CVRow] {
        var rows: [CVRow] = []
        let titleRow: CVRow = CVRow.titleRow(title: title) { [weak self] cell in
            self?.navigationChildController?.updateLabel(titleLabel: cell.cvTitleLabel, containerView: cell)
        }
        rows.append(titleRow)
        let sections: [PrivacySection] = PrivacyManager.shared.privacySections
        let sectionsRows: [CVRow] = sections.map { section in
            let sectionRow: CVRow = CVRow(title: section.section,
                                          subtitle: section.description,
                                          xibName: .textCell,
                                          theme: CVRow.Theme(topInset: 30.0,
                                                             bottomInset: 15.0,
                                                             textAlignment: .natural,
                                                             separatorLeftInset: Appearance.Cell.leftMargin))
            let linkRows: [CVRow] = section.links?.map { link in
                CVRow(title: link.label,
                      xibName: .standardCell,
                      theme: CVRow.Theme(topInset: 15.0,
                                         bottomInset: 15.0,
                                         textAlignment: .natural,
                                         titleFont: { Appearance.Cell.Text.standardFont },
                                         separatorLeftInset: Appearance.Cell.leftMargin),
                      selectionAction: {
                        URL(string: link.url)?.openInSafari()
                      }, willDisplay: { cell in
                        cell.cvTitleLabel?.accessibilityTraits = .button
                })
            } ?? []
            return [sectionRow] + linkRows
        }.reduce([], +)
        rows.append(contentsOf: sectionsRows)
        rows.append(.empty)
        return rows
    }

}

extension OnboardingPrivacyController: PrivacyChangesObserver {
    
    func privacyChanged() {
        reloadUI()
    }
    
}
