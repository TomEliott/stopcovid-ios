// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  CSVExportManager.swift
//  STOP-COVID
//
//  Created by Lunabee Studio / Date - 07/05/2020 - for the STOP-COVID project.
//


import UIKit
import RobertSDK

final class CSVExportManager {

    static func generateLocalProximitiesCSV() -> URL? {
        if !RBManager.shared.localProximityList.isEmpty {
            let header: String = "eccBase64,ebidBase64,macBase64,helloTime,collectedTime,rssi,Ka"
            let lines: [String] = RBManager.shared.localProximityList.map {
                let values: [String] = [$0.ecc, $0.ebid, $0.mac, "\($0.timeFromHelloMessage)", "\($0.timeCollectedOnDevice)", "\($0.rssiRaw)", "-"]
                return values.joined(separator: ",")
            }
            let csv: String = ([header] + lines).joined(separator: "\n")
            do {
                try csv.write(to: csvFileUrl(), atomically: true, encoding: .utf8)
                return csvFileUrl()
            } catch {
                return nil
            }
        } else {
            do {
                let message: String = """
                No data available
                Local proximity list count: \(RBManager.shared.localProximityList.count)
                """
                try message.write(to: csvFileUrl(), atomically: true, encoding: .utf8)
                return csvFileUrl()
            } catch {
                return nil
            }
        }
    }
    
    static func deleteLastExport() {
        try? FileManager.default.removeItem(at: csvFileUrl())
    }
    
    private static func csvFileUrl() -> URL {
        URL(fileURLWithPath: "\(NSTemporaryDirectory())/localProximityList.csv")
    }
    
}
