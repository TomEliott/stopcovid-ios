// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  DeviceParametersManager.swift
//  STOP-COVID
//
//  Created by Lunabee Studio / Date - 14/05/2020 - for the STOP-COVID project.
//


import UIKit

final class DeviceParametersManager {
    
    static func getDeviceParametersFor(model: String) -> DeviceParameters? {
        guard let jsonUrl = Bundle.main.url(forResource: "device_parameters_correction", withExtension: "json") else { return nil }
        guard let data = try? Data(contentsOf: jsonUrl) else { return nil }
        let devicesParameters: [DeviceParameters] = (try? JSONDecoder().decode([DeviceParameters].self, from: data)) ?? []
        if let parameters = devicesParameters.filter({ $0.model == model }).first {
            return parameters
        } else {
            let txAverage: Double = devicesParameters.reduce(0) { $0 + $1.txFactor } / Double(devicesParameters.count)
            let rxAverage: Double = devicesParameters.reduce(0) { $0 + $1.rxFactor } / Double(devicesParameters.count)
            return DeviceParameters(model: "-", txFactor: txAverage, rxFactor: rxAverage)
        }
    }
    
}
