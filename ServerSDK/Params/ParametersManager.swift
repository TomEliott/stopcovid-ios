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

public final class ParametersManager: NSObject {
    
    typealias RequestCompletion = (_ result: Result<Double, Error>) -> ()
    
    public static let shared: ParametersManager = ParametersManager()
    var url: URL!
    
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
    public var statusTimeInterval: Double {
        let randomStatusHour: Double = self.randomStatusHour ?? 0.0
        let interval: Double = (self.checkStatusFrequency ?? 0.0) * 3600.0 + (randomStatusHour == 0.0 ? 0.0 : Double.random(in: 0..<randomStatusHour * 3600.0))
        return interval
    }
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
    
    private var receivedData: [String: Data] = [:]
    private var completions: [String: RequestCompletion] = [:]
    
    private lazy var session: URLSession = {
        let backgroundConfiguration: URLSessionConfiguration = URLSessionConfiguration.background(withIdentifier: "fr.gouv.stopcovid.ios.ServerSDK-Config")
        backgroundConfiguration.timeoutIntervalForRequest = ServerConstant.timeout
        backgroundConfiguration.timeoutIntervalForResource = ServerConstant.timeout
        return URLSession(configuration: backgroundConfiguration, delegate: self, delegateQueue: .main)
    }()
    
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
    
    // TODO: Fetch config using background url session.
    func fetchConfig(_ completion: @escaping (_ result: Result<Double, Error>) -> ()) {
        let requestId: String = UUID().uuidString
        completions[requestId] = completion
        let task: URLSessionDataTask = session.dataTask(with: url)
        task.taskDescription = requestId
        task.resume()
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
        refreshBackgroundFetchInterval()
    }
    
    private func refreshBackgroundFetchInterval() {
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

extension ParametersManager: URLSessionDelegate, URLSessionDataDelegate {
    
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        let requestId: String = dataTask.taskDescription ?? ""
        guard let completion = completions[requestId] else { return }
        DispatchQueue.main.async {
            if dataTask.response?.svIsError == true {
                let statusCode: Int = dataTask.response?.svStatusCode ?? 0
                let message: String = data.isEmpty ? "No logs received from the server" : (String(data: data, encoding: .utf8) ?? "Unknown error")
                completion(.failure(NSError.svLocalizedError(message: "Uknown error (\(statusCode)). (\(message))", code: statusCode)))
                self.completions[dataTask.taskDescription ?? ""] = nil
            } else {
                var receivedData: Data = self.receivedData[requestId] ?? Data()
                receivedData.append(data)
                self.receivedData[requestId] = receivedData
            }
        }
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        let requestId: String = task.taskDescription ?? ""
        guard let completion = completions[requestId] else { return }
        DispatchQueue.main.async {
            if let error = error {
                completion(.failure(error))
            } else {
                let receivedData: Data = self.receivedData[requestId] ?? Data()
                if task.response!.svIsError == true {
                    let statusCode: Int = task.response?.svStatusCode ?? 0
                    let message: String = receivedData.isEmpty ? "No data received from the server" : (String(data: receivedData, encoding: .utf8) ?? "Unknown error" )
                    completion(.failure(NSError.svLocalizedError(message: "Uknown error (\(statusCode)). (\(message))", code: statusCode)))
                    self.completions[task.taskDescription ?? ""] = nil
                } else {
                    do {
                        let json: [String: Any] = (try JSONSerialization.jsonObject(with: receivedData, options: [])) as? [String: Any] ?? [:]
                        try receivedData.write(to: self.localFileUrl())
                        self.config = json["config"] as? [[String: Any]] ?? []
                        DispatchQueue.main.async {
                            completion(.success(task.response!.serverTime))
                        }
                    } catch {
                        DispatchQueue.main.async {
                            completion(.failure(error))
                        }
                    }
                }
            }
            self.completions[task.taskDescription ?? ""] = nil
        }
    }
    
}
