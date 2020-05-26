/*
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Authors
 * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 * Created by Orange / Date - 2020/05/06 - for the STOP-COVID project
 */

@testable import ProximityNotification
import XCTest

class BluetoothProximityPayloadTests: XCTestCase {
    
    func testInitWithPayloadAndMetadataSucceeds() {
        // Given
        guard let payload = ProximityPayload(data: Data(Array(0..<16))) else {
            XCTFail("Could not initialize ProximityPayload")

            return
        }
        
        let txPowerLevel = Int8(15)
        
        // When
        let bluetoothProximityPayload = BluetoothProximityPayload(payload: payload, txPowerLevel: txPowerLevel)
        
        // Then
        XCTAssertEqual(18, bluetoothProximityPayload.data.count)
        XCTAssertEqual(payload, bluetoothProximityPayload.payload)
        XCTAssertEqual(txPowerLevel, bluetoothProximityPayload.txPowerLevel)
        XCTAssertEqual(0, Int8(bitPattern: bluetoothProximityPayload.data[16]))
    }
    
    func testInitWithDataSucceeds() {
        // Given
        let data = Data(Array(0..<24))
        
        // When
        let bluetoothProximityPayload = BluetoothProximityPayload(data: data)
        
        // Then
        XCTAssertNotNil(bluetoothProximityPayload)
        if let bluetoothProximityPayload = bluetoothProximityPayload {
            XCTAssertEqual(18, bluetoothProximityPayload.data.count)
            XCTAssertEqual(data.prefix(16), bluetoothProximityPayload.payload.data)
            XCTAssertEqual(17, bluetoothProximityPayload.txPowerLevel)
            XCTAssertEqual(16, Int8(bitPattern: bluetoothProximityPayload.data[16]))
        }
    }
    
    func testInitWithTruncatedDataFails() {
        // Given
        let data = Data(Array(0..<17))
        
        // When
        let bluetoothProximityPayload = BluetoothProximityPayload(data: data)
        
        // Then
        XCTAssertNil(bluetoothProximityPayload)
    }
}
