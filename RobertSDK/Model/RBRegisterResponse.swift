// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  RBRegisterResponse.swift
//  STOP-COVID
//
//  Created by Lunabee Studio / Date - 29/04/2020 - for the STOP-COVID project.
//

import UIKit

public struct RBRegisterResponse {

    let key: String
    let epochs: [RBEpoch]
    let timeStart: Int
    let filteringAlgoConfig: [[String: Any]]
    
    public init(key: String, epochs: [RBEpoch], timeStart: Int, filteringAlgoConfig: [[String: Any]]) {
        self.key = key
        self.epochs = epochs
        self.timeStart = timeStart
        self.filteringAlgoConfig = filteringAlgoConfig
    }
    
}
