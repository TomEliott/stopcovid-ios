// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  ServerConstant.swift
//  STOP-COVID
//
//  Created by Lunabee Studio / Date - 27/04/2020 - for the STOP-COVID project.
//

import Foundation

struct ServerConstant {

    struct Url {
        static let base: URL = URL(string: "https://")!
        static let status: URL = Url.base.appendingPathComponent("status")
        static let report: URL = Url.base.appendingPathComponent("report")
        static let register: URL = Url.base.appendingPathComponent("register")
        static let unregister: URL = Url.base.appendingPathComponent("unregister")
        static let deleteExposureHistory: URL = Url.base.appendingPathComponent("deleteExposureHistory")
    }
    
    static let acceptedReportCodeLength: [Int] = [6, 36]
    static let quarantineDurationInDays: Int = 14
    static let statusRequestFrequencyInHours: Double = 24.0
    
}
