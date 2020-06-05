// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  ParametersManager.swift
//  STOP-COVID
//
//  Created by Lunabee Studio / Date - 14/05/2020 - for the STOP-COVID project.
//


import UIKit
import RobertSDK

public final class ParametersManager {
    
    public static let shared: ParametersManager = ParametersManager()
    public var url: URL!
    
    public var minHourContactNotif: Int? {
        guard let hour = valueFor(name: "app.minHourContactNotif") as? Double else { return nil }
        return Int(hour)
    }
    public var maxHourContactNotif: Int? {
           guard let hour = valueFor(name: "app.maxHourContactNotif") as? Double else { return nil }
           return Int(hour)
       }
    var appAvailability: Bool? { valueFor(name: "app.appAvailability") as? Bool }
    var preSymptomsSpan: Int? {
        guard let span = valueFor(name: "app.preSymptomsSpan") as? Double else { return nil }
        return Int(span)
    }
    var checkStatusFrequency: Double? { valueFor(name: "app.checkStatusFrequency") as? Double }
    var randomStatusHour: Double? { valueFor(name: "app.randomStatusHour") as? Double }
    public var quarantinePeriod: Int? {
        guard let period = valueFor(name: "app.quarantinePeriod") as? Double else { return nil }
        return Int(period)
    }
    var dataRetentionPeriod: Int? {
        guard let period = valueFor(name: "app.dataRetentionPeriod") as? Double else { return nil }
        return Int(period)
    }
    public var bleServiceUuid: String? { valueFor(name: "ble.serviceUUID") as? String }
    public var bleCharacteristicUuid: String? { valueFor(name: "ble.characteristicUUID") as? String }
    
    private var config: [[String: Any]] = [] {
        didSet { distributeUpdatedConfig() }
    }
    private var shouldUpdateFetchTimeInterval: Bool = false
    
    public func start() {
        loadLocalConfigIfPossible()
    }
    
    public func getDeviceParametersFor(model: String) -> DeviceParameters? {
        guard let deviceCalibration = valueFor(name: "ble.calibration") as? [[String: Any]] else { return nil }
        guard let data = try? JSONSerialization.data(withJSONObject: deviceCalibration, options: []) else { return nil }
        let devicesParameters: [DeviceParameters] = (try? JSONDecoder().decode([DeviceParameters].self, from: data)) ?? []
        if let parameters = devicesParameters.filter({ $0.model == model }).first {
            return parameters
        } else if let parameters = devicesParameters.filter({ $0.model == "iPhone" }).first, UIDevice.current.userInterfaceIdiom == .phone {
            return parameters
        } else if let parameters = devicesParameters.filter({ $0.model == "iPad" }).first, UIDevice.current.userInterfaceIdiom == .pad {
            return parameters
        } else if let parameters = devicesParameters.filter({ $0.model == "DEFAULT" }).first {
            return parameters
        } else {
            let txAverage: Double = -15
            let rxAverage: Double = -5
            return DeviceParameters(model: "-", txFactor: txAverage, rxFactor: rxAverage)
        }
    }
    
    func fetchConfig(_ completion: @escaping (_ error: Error?) -> ()) {
        let dataTask: URLSessionDataTask = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data else { return }
            do {
                let json: [String: Any] = (try JSONSerialization.jsonObject(with: data, options: [])) as? [String: Any] ?? [:]
                self.shouldUpdateFetchTimeInterval = true
                self.config = json["config"] as? [[String: Any]] ?? []
                try data.write(to: self.localFileUrl())
                DispatchQueue.main.async {
                    completion(nil)
                }
            } catch {
                DispatchQueue.main.async {
                    completion(error)
                }
            }
        }
        dataTask.resume()
    }
    
    public func clearConfig() {
        config = []
        try? FileManager.default.removeItem(at: localFileUrl())
    }
    
    private func loadLocalConfigIfPossible() {
        guard let data = try? Data(contentsOf: localFileUrl()) else { return }
        guard let json = (try? JSONSerialization.jsonObject(with: data, options: [])) as? [String: Any] else { return }
        self.config = json["config"] as? [[String: Any]] ?? []
    }
    
    private func valueFor(name: String) -> Any? {
        config.first { $0["name"] as? String == name }?["value"]
    }
    
    private func distributeUpdatedConfig() {
        RBManager.shared.proximitiesRetentionDurationInDays = dataRetentionPeriod
        RBManager.shared.preSymptomsSpan = preSymptomsSpan
        if RBManager.shared.isProximityActivated {
            RBManager.shared.stopProximityDetection()
            RBManager.shared.startProximityDetection()
        }
        DispatchQueue.main.async {
            self.refreshBackgroundFetchInterval()
        }
    }
    
    private func refreshBackgroundFetchInterval() {
        guard shouldUpdateFetchTimeInterval else { return }
        shouldUpdateFetchTimeInterval = false
        if let checkStatusFrequency = checkStatusFrequency {
            let randomStatusHour: Double = self.randomStatusHour ?? 0.0
            let interval: Double = checkStatusFrequency * 3600.0 + (randomStatusHour == 0.0 ? 0.0 : Double.random(in: 0..<randomStatusHour * 3600.0))
            UIApplication.shared.setMinimumBackgroundFetchInterval(interval)
        }
    }
    
    private func createWorkingDirectoryIfNeeded() -> URL {
        let directoryUrl: URL = FileManager.svLibraryDirectory().appendingPathComponent("config")
        if !FileManager.default.fileExists(atPath: directoryUrl.path, isDirectory: nil) {
            try? FileManager.default.createDirectory(at: directoryUrl, withIntermediateDirectories: false, attributes: nil)
        }
        return directoryUrl
    }
    
    private func localFileUrl() -> URL {
        createWorkingDirectoryIfNeeded().appendingPathComponent("config.json")
    }
    
}
