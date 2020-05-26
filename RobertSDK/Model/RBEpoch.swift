// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  RBEpoch.swift
//  STOP-COVID
//
//  Created by Lunabee Studio / Date - 23/04/2020 - for the STOP-COVID project.
//

import UIKit

public struct RBEpoch: RBStorable {
    
    public let id: Int
    public let ebid: String
    public let ecc: String
    
    public init(id: Int, ebid: String, ecc: String) {
        self.id = id
        self.ebid = ebid
        self.ecc = ecc
    }
    
}
