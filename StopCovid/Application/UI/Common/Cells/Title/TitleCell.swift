//
//  TitleCell.swift
//  StopCovid
//
//  Created by Nicolas on 03/06/2020.
//  Copyright © 2020 Lunabee Studio. All rights reserved.
//

import UIKit

final class TitleCell: CVTableViewCell {

    override func setup(with row: CVRow) {
        super.setup(with: row)
        setupAccessibility()
    }
    
    private func setupAccessibility() {
        cvTitleLabel?.accessibilityTraits = [.staticText, .header]
    }

}
