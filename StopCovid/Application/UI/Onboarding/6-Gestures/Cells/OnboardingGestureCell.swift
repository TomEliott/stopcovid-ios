// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  OnboardingGestureCell.swift
//  STOP-COVID
//
//  Created by Lunabee Studio / Date - 08/04/2020 - for the STOP-COVID project.
//

import UIKit

final class OnboardingGestureCell: CVTableViewCell {
    
    override func setup(with row: CVRow) {
        super.setup(with: row)
        cvTitleLabel?.font = Appearance.Cell.Text.standardFont
    }

}
