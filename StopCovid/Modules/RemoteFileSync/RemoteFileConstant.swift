// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  RemoteFileConstant.swift
//  STOP-COVID
//
//  Created by Lunabee Studio / Date - 18/05/2020 - for the STOP-COVID project.
//


import UIKit

enum RemoteFileConstant {

    static let baseUrl = "https://app.stopcovid.gouv.fr/json/version-22"
    
    static let useOnlyLocalStrings: Bool = ProcessInfo.processInfo.environment["LOCAL_STRINGS"] == "YES"
    static let minDurationBetweenUpdatesInSeconds: Double = 1.0 * 3600.0
    
}
