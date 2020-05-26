// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  BluetoothAuthorizationManager.swift
//  STOP-COVID
//
//  Created by Lunabee Studio / Date - 30/04/2020 - for the STOP-COVID project.
//

import UIKit
import CoreBluetooth

final class BluetoothAuthorizationManager: NSObject {
    
    static let shared: BluetoothAuthorizationManager = BluetoothAuthorizationManager()
    var isAuthorized: Bool?
    var isActivated: Bool?
    
    private var centralManager: CBCentralManager?
    private var authorizationHandler: (() -> ())?
    private var isAuthorizedHandler: ((_ isAuthorized: Bool) -> ())?
    
    func requestAuthorizations(_ completion: @escaping () -> ()) {
        authorizationHandler = completion
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func isBluetoothAuthorized(_ completion: @escaping (_ isAuthorized: Bool) -> ()) {
        isAuthorizedHandler = completion
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
}

extension BluetoothAuthorizationManager: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .unknown, .unsupported:
            isAuthorized = false
            isActivated = false
            break
        default:
            isAuthorized = central.state != .unauthorized
            isActivated = central.state == .poweredOn
            centralManager = nil
        }
        if authorizationHandler != nil {
            DispatchQueue.main.async {
                self.authorizationHandler?()
                self.authorizationHandler = nil
            }
        }
        if isAuthorizedHandler != nil {
            DispatchQueue.main.async {
                self.isAuthorizedHandler?(central.state != .unauthorized)
                self.isAuthorizedHandler = nil
            }
        }
    }
    
}
