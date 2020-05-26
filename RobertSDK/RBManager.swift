// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  RBManager.swift
//  STOP-COVID
//
//  Created by Lunabee Studio / Date - 27/04/2020 - for the STOP-COVID project.
//

import UIKit

public final class RBManager {

    public static let shared: RBManager = RBManager()
    
    private var server: RBServer!
    private var storage: RBStorage!
    private var bluetooth: RBBluetooth!
    private var ka: Data?
    
    public var isRegistered: Bool { storage.isKeyStored() && storage.getLastEpoch() != nil }
    public var isProximityActivated: Bool {
        get { storage.isProximityActivated() }
        set { storage.save(proximityActivated: newValue) }
    }
    public var isSick: Bool {
        get { storage.isSick() }
        set { storage.save(isSick: newValue) }
    }
    public var isAtRisk: Bool? {
        get { storage.isAtRisk() }
        set { storage.save(isAtRisk: newValue) }
    }
    public var lastStatusReceivedDate: Date? {
        get { storage.lastStatusReceivedDate() }
        set { storage.saveLastStatusReceivedDate(newValue) }
    }
    public var currentEpoch: RBEpoch? { storage.getCurrentEpoch() }
    public var localProximityList: [RBLocalProximity] { storage.getLocalProximityList() }

    private init() {}
    
    public func start(isFirstInstall: Bool = false, server: RBServer, storage: RBStorage, bluetooth: RBBluetooth, restartProximityIfPossible: Bool = true) {
        self.server = server
        self.storage = storage
        self.bluetooth = bluetooth
        if isFirstInstall {
            self.storage.clearAll(includingDBKey: true)
        }
        self.storage.start()
        loadKey()
        if isProximityActivated && restartProximityIfPossible && !isFirstInstall {
            startProximityDetection()
        }
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillTerminate), name: UIApplication.willTerminateNotification, object: nil)
    }
    
    public func startProximityDetection() {
        guard let ka = ka else { return }
        bluetooth.start(helloMessageCreationHandler: { completion in
            DispatchQueue.main.async {
                if let epoch = self.storage.getCurrentEpoch() {
                    let ntpTimestamp: Int = Date().timeIntervalSince1900
                    do {
                        let data = try RBMessageGenerator.generateHelloMessage(for: epoch, ntpTimestamp: ntpTimestamp, key: ka)
                        completion(data)
                    } catch {
                        completion(nil)
                    }
                } else {
                    completion(nil)
                }
            }
        }, ebidExtractionHandler: { helloMessage -> Data in
            RBMessageParser.getEbid(from: helloMessage) ?? Data()
        }, didReceiveProximity: { [weak self] receivedProximity in
            DispatchQueue.main.async {
                let eccString: String? = RBMessageParser.getEcc(from: receivedProximity.data)?.base64EncodedString()
                let ebidString: String? = RBMessageParser.getEbid(from: receivedProximity.data)?.base64EncodedString()
                let timeInt: UInt16? = RBMessageParser.getTime(from: receivedProximity.data)
                let macString: String? = RBMessageParser.getMac(from: receivedProximity.data)?.base64EncodedString()
                guard let ecc = eccString, let ebid = ebidString, let time = timeInt, let mac = macString else {
                    return
                }
                let localProximity: RBLocalProximity = RBLocalProximity(ecc: ecc,
                                                                        ebid: ebid,
                                                                        mac: mac,
                                                                        timeFromHelloMessage: time,
                                                                        timeCollectedOnDevice: receivedProximity.timeCollectedOnDevice,
                                                                        rssiRaw: receivedProximity.rssiRaw,
                                                                        rssiCalibrated: receivedProximity.rssiCalibrated,
                                                                        tx: receivedProximity.tx)
                self?.storage.save(localProximity: localProximity)
            }
        })
    }
    
    public func stopProximityDetection() {
        bluetooth.stop()
    }
    
    private func loadKey() {
        if let key = storage.getKey() {
            ka = key
        }
    }
    
    private func wipeKey() {
        ka?.wipeData()
    }
    
    @objc private  func applicationWillTerminate() {
        wipeKey()
        storage.stop()
    }
    
}

// MARK: - Server methods -
extension RBManager {
    
    public func status(_ completion: @escaping (_ error: Error?) -> ()) {
        guard let ka = ka else {
            completion(NSError.rbLocalizedError(message: "No key found to make request", code: 0))
            return
        }
        guard let epoch = storage.getCurrentEpoch() else {
            completion(NSError.rbLocalizedError(message: "No epoch found to make request", code: 0))
            return
        }
        do {
            let ntpTimestamp: Int = Date().timeIntervalSince1900
            let statusMessage: RBStatusMessage = try RBMessageGenerator.generateStatusMessage(for: epoch, ntpTimestamp: ntpTimestamp, key: ka)
            server.status(ebid: statusMessage.ebid, time: statusMessage.time, mac: statusMessage.mac) { result in
                switch result {
                case let .success(response):
                    do {
                        try self.processStatusResponse(response)
                        completion(nil)
                    } catch {
                        completion(error)
                    }
                case let .failure(error):
                    completion(error)
                }
            }
        } catch {
            completion(error)
        }
    }
    
    public func report(code: String, completion: @escaping (_ error: Error?) -> ()) {
        let localHelloMessages: [RBLocalProximity] = storage.getLocalProximityList()
        server.report(code: code, helloMessages: localHelloMessages) { error in
            if let error = error {
                completion(error)
            } else {
                self.isSick = true
                completion(nil)
            }
        }
    }
    
    public func registerIfNeeded(token: String, completion: @escaping (_ error: Error?) -> ()) {
        if isRegistered {
            completion(nil)
        } else {
            register(token: token, completion: completion)
        }
    }
    
    public func register(token: String, completion: @escaping (_ error: Error?) -> ()) {
        server.register(token: token) { result in
            switch result {
            case let .success(response):
                do {
                    try self.processRegisterResponse(response)
                    completion(nil)
                } catch {
                    completion(error)
                }
            case let .failure(error):
                completion(error)
            }
        }
    }
    
    public func unregister(_ completion: @escaping (_ error: Error?) -> ()) {
        guard isRegistered else {
            isProximityActivated = false
            stopProximityDetection()
            clearAllLocalData()
            completion(nil)
            return
        }
        guard let ka = ka else {
            completion(NSError.rbLocalizedError(message: "No key found to make request", code: 0))
            return
        }
        guard let epoch = storage.getCurrentEpoch() else {
            completion(NSError.rbLocalizedError(message: "No epoch found to make request", code: 0))
            return
        }
        do {
            let ntpTimestamp: Int = Date().timeIntervalSince1900
            let statusMessage: RBUnregisterMessage = try RBMessageGenerator.generateUnregisterMessage(for: epoch, ntpTimestamp: ntpTimestamp, key: ka)
            server.unregister(ebid: statusMessage.ebid, time: statusMessage.time, mac: statusMessage.mac, completion: { error in
                if let error = error {
                    completion(error)
                } else {
                    self.isProximityActivated = false
                    self.stopProximityDetection()
                    self.clearAllLocalData()
                    completion(nil)
                }
            })
        } catch {
            completion(error)
        }
    }
    
    public func deleteExposureHistory(_ completion: @escaping (_ error: Error?) -> ()) {
        guard let ka = ka else {
            completion(NSError.rbLocalizedError(message: "No key found to make request", code: 0))
            return
        }
        guard let epoch = storage.getCurrentEpoch() else {
            completion(NSError.rbLocalizedError(message: "No epoch found to make request", code: 0))
            return
        }
        do {
            let ntpTimestamp: Int = Date().timeIntervalSince1900
            let statusMessage: RBDeleteExposureHistoryMessage = try RBMessageGenerator.generateDeleteExposureHistoryMessage(for: epoch, ntpTimestamp: ntpTimestamp, key: ka)
            server.deleteExposureHistory(ebid: statusMessage.ebid, time: statusMessage.time, mac: statusMessage.mac, completion: { error in
                if let error = error {
                    completion(error)
                } else {
                    completion(nil)
                }
            })
        } catch {
            completion(error)
        }
    }
    
    public func clearLocalEpochs() {
        storage.clearLocalEpochs()
    }
    
    public func clearLocalProximityList() {
        storage.clearLocalProximityList()
    }
    
    public func clearAtRiskAlert() {
        storage.save(isAtRisk: nil)
    }
    
    public func clearAllLocalData() {
        storage.clearAll(includingDBKey: false)
        clearKey()
    }
    
    func clearKey() {
        ka?.wipeData()
        ka = nil
    }
    
}

extension RBManager {
    
    private func processRegisterResponse(_ response: RBRegisterResponse) throws {
        guard let data = Data(base64Encoded: response.key) else {
            throw NSError.rbLocalizedError(message: "The provided key is not a valid base64 string", code: 0)
        }
        storage.save(key: data)
        ka = data
        try storage.save(timeStart: response.timeStart)
        if !response.epochs.isEmpty {
            clearLocalEpochs()
            storage.save(epochs: response.epochs)
        }
    }
    
    private func processStatusResponse(_ response: RBStatusResponse) throws {
        storage.save(isAtRisk: response.atRisk)
        storage.save(lastExposureTimeFrame: response.lastExposureTimeFrame)
        if !response.epochs.isEmpty {
            clearLocalEpochs()
            storage.save(epochs: response.epochs)
        }
        lastStatusReceivedDate = Date()
    }
    
}
