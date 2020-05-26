/*
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Authors
 * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 * Created by Orange / Date - 2020/05/19 - for the STOP-COVID project
 */

import Foundation

protocol BluetoothCentralManagerProtocol: class {
    
    var delegate: BluetoothCentralManagerDelegate? { get set }
    
    var state: ProximityNotificationState { get }
    
    func start(proximityPayloadProvider: @escaping ProximityPayloadProvider)
    
    func stop()
}
