// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  BluetoothManager.swift
//  STOP-COVID
//
//  Created by Lunabee Studio / Date - 30/04/2020 - for the STOP-COVID project.
//

import UIKit
import ProximityNotification
import RobertSDK

final class BluetoothManager: RBBluetooth {
    
    private var service: ProximityNotificationService?
    
    private var serviceUUID: String!
    private var characteristicUUID: String!
    
    init(serviceUUID: String, characteristicUUID: String) {
        self.serviceUUID = serviceUUID
        self.characteristicUUID = characteristicUUID
    }
    
    func start(helloMessageCreationHandler: @escaping (_ completion: @escaping (_ data: Data?) -> ()) -> (),
               ebidExtractionHandler: @escaping (_ data: Data) -> Data,
               didReceiveProximity: @escaping (_ proximity: RBReceivedProximity) -> ()) {
        
        let deviceParameters: DeviceParameters? = DeviceParametersManager.getDeviceParametersFor(model: UIDevice.current.model)
        let bleSettings = BluetoothSettings(serviceUniqueIdentifier: serviceUUID,
                                            serviceCharacteristicUniqueIdentifier: characteristicUUID,
                                            txCompensationGain: Int8(deviceParameters?.txFactor ?? 0.0),
                                            rxCompensationGain: Int8(deviceParameters?.rxFactor ?? 0.0))
        let stateChangedHandler: StateChangedHandler = { _ in }
        service = ProximityNotificationService(settings: ProximityNotificationSettings(bluetoothSettings: bleSettings),
                                               stateChangedHandler: stateChangedHandler)
        
        let proximityPayloadProvider: ProximityPayloadProvider = { () -> ProximityPayload? in
            var data: Data?
            let semaphore: DispatchSemaphore = DispatchSemaphore(value: 0)
            helloMessageCreationHandler { helloMessageData in
                data = helloMessageData
                semaphore.signal()
            }
            semaphore.wait()
            return ProximityPayload(data: data ?? Data())
        }
        let identifierFromProximityPayload: IdentifierFromProximityPayload = { proximityPayload -> Data? in
            return ebidExtractionHandler(proximityPayload.data)
        }
        let proximityInfoUpdateHandler: ProximityInfoUpdateHandler = { proximity in
            DispatchQueue.main.async {
                guard let metadata = proximity.metadata as? BluetoothProximityMetadata else { return }
                let proximity: RBReceivedProximity = RBReceivedProximity(data: proximity.payload.data,
                                                                         timeCollectedOnDevice: proximity.timestamp.timeIntervalSince1900,
                                                                         rssiRaw: metadata.rawRSSI,
                                                                         rssiCalibrated: metadata.calibratedRSSI,
                                                                         tx: metadata.txPowerLevel)
                didReceiveProximity(proximity)
            }
        }
        
        service?.start(proximityPayloadProvider: proximityPayloadProvider,
                      proximityInfoUpdateHandler: proximityInfoUpdateHandler,
                      identifierFromProximityPayload: identifierFromProximityPayload)
    }
    
    func stop() {
        service?.stop()
        service = nil
    }
    
}
