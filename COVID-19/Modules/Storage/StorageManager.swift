// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  StorageManager.swift
//  STOP-COVID
//
//  Created by Lunabee Studio / Date - 27/04/2020 - for the STOP-COVID project.
//

import UIKit
import KeychainSwift
import RealmSwift
import RobertSDK

final class StorageManager: RBStorage {
    
    enum KeychainKey: String, CaseIterable {
        case dbKey
        case epochTimeStart
        case key
        case proximityActivated
        case isAtRisk
        case lastExposureTimeFrame
        case lastStatusReceivedDate
        case isSick
        case positiveToSymptoms
    }
    
    let keychain: KeychainSwift = KeychainSwift(keyPrefix: "SC")
    private var realm: Realm?
    private var dbKey: Data?
    
    func start() {
        loadDbKey()
    }
    
    func stop() {
        wipeDBKey()
    }
    
    // MARK: - Epoch -
    func save(epochs: [RBEpoch]) {
        guard let realm = realm else { return }
        let realmEpochs: [RealmEpoch] = epochs.map { RealmEpoch.from(epoch: $0) }
        try! realm.write {
            realm.add(realmEpochs, update: .all)
        }
    }
    
    func getCurrentEpoch() -> RBEpoch? {
        do {
            let timeStart: Int = try getTimeStart()
            let now: Int = Date().timeIntervalSince1900
            let quartersCount: Int = Int(Double(now - timeStart) / Double(RBConstants.epochDurationInSeconds))
            return getEpoch(for: quartersCount) ?? getLastEpoch()
        } catch {
            return nil
        }
    }
    
    func getEpoch(for id: Int) -> RBEpoch? {
        guard let realm = realm else { return nil }
        return realm.object(ofType: RealmEpoch.self, forPrimaryKey: id)?.toRBEpoch()
    }
    
    func getLastEpoch() -> RBEpoch? {
        guard let realm = realm else { return nil }
        return realm.objects(RealmEpoch.self).sorted { $0.id < $1.id }.last?.toRBEpoch()
    }
    
    // MARK: - TimeStart -
    func save(timeStart: Int) throws {
        guard let data = "\(timeStart)".data(using: .utf8) else { throw NSError.localizedError(message: "Can't generate data from timeStart", code: 400) }
        keychain.set(data, forKey: KeychainKey.epochTimeStart.rawValue, withAccess: .accessibleAfterFirstUnlockThisDeviceOnly)
    }
    
    func getTimeStart() throws -> Int {
        guard let data = keychain.getData(KeychainKey.epochTimeStart.rawValue) else { throw NSError.localizedError(message: "timeStart not found in Keychain", code: 404) }
        guard let timeString = String(data: data, encoding: .utf8),
              let timeStart = Int(timeString) else { throw NSError.localizedError(message: "Can't generate Int from timeStart data", code: 400) }
        return timeStart
    }
    
    // MARK: - Key -
    func save(key: Data) {
        keychain.set(key, forKey: KeychainKey.key.rawValue, withAccess: .accessibleAfterFirstUnlockThisDeviceOnly)
    }
    
    func getKey() -> Data? {
        keychain.getData(KeychainKey.key.rawValue)
    }
    
    func isKeyStored() -> Bool {
        keychain.getData(KeychainKey.key.rawValue) != nil
    }
    
    // MARK: - Local Proximity -
    func save(localProximity: RBLocalProximity) {
        guard let realm = realm else { return }
        let proximity: RealmLocalProximity = RealmLocalProximity.from(localProximity: localProximity)
        if realm.object(ofType: RealmLocalProximity.self, forPrimaryKey: proximity.id) == nil {
            try! realm.write {
                realm.add(proximity, update: .all)
            }
            notifyLocalProximityDataChanged()
        }
    }
    
    func getLocalProximityList() -> [RBLocalProximity] {
        guard let realm = realm else { return [] }
        return realm.objects(RealmLocalProximity.self).map { $0.toRBLocalProximity() }
    }
    
    // MARK: - Proximity -
    func save(proximityActivated: Bool) {
        keychain.set(proximityActivated, forKey: KeychainKey.proximityActivated.rawValue, withAccess: .accessibleAfterFirstUnlockThisDeviceOnly)
        notifyStatusDataChanged()
    }
    
    func isProximityActivated() -> Bool {
        keychain.getBool(KeychainKey.proximityActivated.rawValue) ?? false
    }
    
    // MARK: - Status: isAtRisk -
    func save(isAtRisk: Bool?) {
        if let isAtRisk = isAtRisk {
            keychain.set(isAtRisk, forKey: KeychainKey.isAtRisk.rawValue, withAccess: .accessibleAfterFirstUnlockThisDeviceOnly)
            if isAtRisk {
                NotificationsManager.shared.scheduleAtRiskNotification()
            }
        } else {
            keychain.delete(KeychainKey.isAtRisk.rawValue)
        }
        notifyStatusDataChanged()
    }
    
    func isAtRisk() -> Bool? {
        keychain.getBool(KeychainKey.isAtRisk.rawValue)
    }
    
    // MARK: - Status: last exposure time frame -
    func save(lastExposureTimeFrame: Int?) {
        if let lastExposureTimeFrame = lastExposureTimeFrame {
            keychain.set("\(lastExposureTimeFrame)", forKey: KeychainKey.lastExposureTimeFrame.rawValue, withAccess: .accessibleAfterFirstUnlockThisDeviceOnly)
        } else {
            keychain.delete(KeychainKey.lastExposureTimeFrame.rawValue)
        }
        notifyStatusDataChanged()
    }
    
    func lastExposureTimeFrame() -> Int? {
        guard let lastExposureString = keychain.get(KeychainKey.lastExposureTimeFrame.rawValue), let lastExposure = Int(lastExposureString) else { return nil }
        return lastExposure
    }
    
    // MARK: - Status: last status received date -
    func saveLastStatusReceivedDate(_ date: Date?) {
        if let date = date {
            keychain.set("\(date.timeIntervalSince1970)", forKey: KeychainKey.lastStatusReceivedDate.rawValue, withAccess: .accessibleAfterFirstUnlockThisDeviceOnly)
        } else {
            keychain.delete(KeychainKey.lastStatusReceivedDate.rawValue)
        }
        notifyStatusDataChanged()
    }
    
    func lastStatusReceivedDate() -> Date? {
        guard let timestampString = keychain.get(KeychainKey.lastStatusReceivedDate.rawValue), let timestamp = Double(timestampString) else { return nil }
        return Date(timeIntervalSince1970: timestamp)
    }
    
    // MARK: - Status: Is sick -
    func save(isSick: Bool) {
        keychain.set(isSick, forKey: KeychainKey.isSick.rawValue, withAccess: .accessibleAfterFirstUnlockThisDeviceOnly)
        notifyStatusDataChanged()
    }
    
    func isSick() -> Bool {
        keychain.getBool(KeychainKey.isSick.rawValue) ?? false
    }
    
    // MARK: - Data cleraing -
    func clearLocalEpochs() {
       guard let realm = realm else { return }
        try! realm.write {
            realm.delete(realm.objects(RealmEpoch.self))
        }
    }
    
    func clearLocalProximityList() {
        guard let realm = realm else { return }
        try! realm.write {
            realm.delete(realm.objects(RealmLocalProximity.self))
        }
        notifyLocalProximityDataChanged()
    }
    
    func clearAll(includingDBKey: Bool) {
        KeychainKey.allCases.forEach {
            if $0 != .dbKey || includingDBKey {
                keychain.delete($0.rawValue)
            }
        }
        try? realm?.write {
            realm?.deleteAll()
        }
        Realm.deleteDb()
    }
    
    func wipeDBKey() {
        dbKey?.wipe()
        dbKey = nil
    }
    
    // MARK: - DB Key -
    private func loadDbKey() {
        if let key = getDbKey() {
            realm = try! Realm.db(key: key)
            dbKey = key
        } else if let newKey = Realm.generateEncryptionKey(), !keychain.allKeys.contains("SC\(KeychainKey.dbKey.rawValue)") {
            realm = try! Realm.db(key: newKey)
            save(dbKey: newKey)
        }
    }
    
    private func save(dbKey: Data) {
        keychain.set(dbKey, forKey: KeychainKey.dbKey.rawValue, withAccess: .accessibleAfterFirstUnlockThisDeviceOnly)
        self.dbKey = dbKey
    }
    
    private func getDbKey() -> Data? {
        guard let data = keychain.getData(KeychainKey.dbKey.rawValue) else { return nil }
        return data
    }
    
}

extension StorageManager {
    
    func notifyStatusDataChanged() {
        NotificationCenter.default.post(name: .statusDataDidChange, object: nil)
    }
    
    func notifyLocalProximityDataChanged() {
        NotificationCenter.default.post(name: .localProximityDataDidChange, object: nil)
    }
    
    @objc func applicationWillTerminate() {
        wipeDBKey()
    }
    
}

extension Realm {
    
    static func db(key: Data?) throws -> Realm {
        guard let key = key else { throw NSError.localizedError(message: "Impossible to decrypt the database", code: 0) }
        return try Realm(configuration: configuration(key: key))
    }
    
    static func deleteDb() {
        try? FileManager.default.removeItem(at: dbsDirectoryUrl().appendingPathComponent("db.realm"))
        try? FileManager.default.removeItem(at: dbsDirectoryUrl().appendingPathComponent("db.lock"))
        try? FileManager.default.removeItem(at: dbsDirectoryUrl().appendingPathComponent("db.note"))
        try? FileManager.default.removeItem(at: dbsDirectoryUrl().appendingPathComponent("db.management"))
    }
    
    static func generateEncryptionKey() -> Data? {
        var keyData: Data = Data(count: 64)
        let result: Int32 = keyData.withUnsafeMutableBytes { SecRandomCopyBytes(kSecRandomDefault, 64, $0.baseAddress!) }
        return result == errSecSuccess ? keyData : nil
    }
    
    static private func dbsDirectoryUrl() -> URL {
        var directoryUrl: URL = FileManager.libraryDirectory().appendingPathComponent("DBs")
        if !FileManager.default.fileExists(atPath: directoryUrl.path, isDirectory: nil) {
            try? FileManager.default.createDirectory(at: directoryUrl, withIntermediateDirectories: false, attributes: nil)
            try? directoryUrl.addSkipBackupAttribute()
        }
        return directoryUrl
    }
    
    static private func configuration(key: Data) -> Realm.Configuration {
        let classes: [Object.Type] = [RealmEpoch.self,
                                      RealmLocalProximity.self,
                                      Permission.self,
                                      PermissionRole.self,
                                      PermissionUser.self]
        let databaseUrl: URL = dbsDirectoryUrl().appendingPathComponent("db.realm")
        let userConfig: Realm.Configuration = Realm.Configuration(fileURL: databaseUrl, encryptionKey: key, schemaVersion: 5, migrationBlock: { _, _ in }, objectTypes: classes)
        return userConfig
    }
    
}
