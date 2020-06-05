//
//  EmptyCell.swift
//  StopCovid
//
//  Created by Nicolas on 01/06/2020.
//  Copyright © 2020 Lunabee Studio. All rights reserved.
//

import UIKit

final class EmptyCell: CVTableViewCell {

    override func setup(with row: CVRow) {
        super.setup(with: row)
        setupAccessibility()
    }
    
    private func setupAccessibility() {
        isAccessibilityElement = false
        accessibilityElementsHidden = true
    }
    
}
