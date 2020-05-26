// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  Constant.swift
//  STOP-COVID
//
//  Created by Lunabee Studio / Date - 08/04/2020 - for the STOP-COVID project.
//

import UIKit

enum Constant {
    
    static let defaultLanguageCode: String = "en"
    
    #if targetEnvironment(simulator)
    static let isSimulator: Bool = true
    #else
    static let isSimulator: Bool = false
    #endif
    
    enum Tab: Int, CaseIterable {
        case proximity
        case sick
        case sharing
    }
    
}

typealias JSON = [String: Any]
