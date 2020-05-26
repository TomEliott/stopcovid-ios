// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  RBReceivedProximity.swift
//  STOP-COVID
//
//  Created by Lunabee Studio / Date - 29/04/2020 - for the STOP-COVID project.
//

import UIKit

public struct RBReceivedProximity {

    let data: Data
    let timeCollectedOnDevice: Int
    let rssiRaw: Int
    let rssiCalibrated: Int
    let tx: Int

    public init(data: Data, timeCollectedOnDevice: Int, rssiRaw: Int, rssiCalibrated: Int, tx: Int) {
        self.data = data
        self.timeCollectedOnDevice = timeCollectedOnDevice
        self.rssiRaw = rssiRaw
        self.rssiCalibrated = rssiCalibrated
        self.tx = tx
    }
    
}
