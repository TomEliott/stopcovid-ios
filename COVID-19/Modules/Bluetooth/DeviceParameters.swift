// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  DeviceParameters.swift
//  STOP-COVID
//
//  Created by Lunabee Studio / Date - 14/05/2020 - for the STOP-COVID project.
//


import UIKit

struct DeviceParameters: Codable {

    var model: String
    var txFactor: Double
    var rxFactor: Double
    
    enum CodingKeys: String, CodingKey {
        case model = "device_handset_model"
        case txFactor = "tx_RSS_correction_factor"
        case rxFactor = "rx_RSS_correction_factor"
    }
    
}
