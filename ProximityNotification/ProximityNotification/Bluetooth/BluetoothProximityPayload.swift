/*
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Authors
 * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 * Created by Orange / Date - 2020/05/06 - for the STOP-COVID project
 */

import Foundation

struct BluetoothProximityPayload {
    
    let data: Data
    
    let payload: ProximityPayload
    
    var txPowerLevel: Int8 {
        return Int8(bitPattern: data[17])
    }
    
    static let byteCount = ProximityPayload.byteCount + 2
    
    init(payload: ProximityPayload, txPowerLevel: Int8) {
        let metadataBytes: [Int8] = [0, txPowerLevel]
        let metadata = Data(metadataBytes.map { UInt8(bitPattern: $0) })
        self.data = payload.data + metadata
        self.payload = payload
    }
    
    init?(data: Data) {
        guard data.count >= BluetoothProximityPayload.byteCount,
            let payload = ProximityPayload(data: data.prefix(ProximityPayload.byteCount)) else {
                return nil
        }
        
        self.data = data.prefix(BluetoothProximityPayload.byteCount)
        self.payload = payload
    }
}
