// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  MainTabBarController.swift
//  STOP-COVID
//
//  Created by Lunabee Studio / Date - 12/04/2020 - for the STOP-COVID project.
//

import UIKit

final class MainTabBarController: UITabBarController {

    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("Must use the other init method")
    }

}
