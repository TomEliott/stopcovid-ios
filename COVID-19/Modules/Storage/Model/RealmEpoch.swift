// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  RealmEpoch.swift
//  STOP-COVID
//
//  Created by Lunabee Studio / Date - 06/05/2020 - for the STOP-COVID project.
//


import UIKit
import RealmSwift
import RobertSDK

final class RealmEpoch: Object {

    @objc dynamic var id: Int = 0
    @objc dynamic var ebid: String!
    @objc dynamic var ecc: String!
    
    static func from(epoch: RBEpoch) -> RealmEpoch {
        RealmEpoch(id: epoch.id, ebid: epoch.ebid, ecc: epoch.ecc)
    }
    
    convenience init(id: Int, ebid: String, ecc: String) {
        self.init()
        self.id = id
        self.ebid = ebid
        self.ecc = ecc
    }
    
    override class func primaryKey() -> String? {
        return "id"
    }
    
    override class func indexedProperties() -> [String] {
        return ["id"]
    }
    
    func toRBEpoch() -> RBEpoch {
        RBEpoch(id: id, ebid: ebid, ecc: ecc)
    }
    
}
