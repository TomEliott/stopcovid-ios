// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  AppDelegate.swift
//  STOP-COVID
//
//  Created by Lunabee Studio / Date - 07/04/2020 - for the STOP-COVID project.
//

import UIKit
import PKHUD
import RobertSDK
import StorageSDK
import ServerSDK

@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate {

    private let rootCoordinator: RootCoordinator = RootCoordinator()
    
    @UserDefault(key: .isAppAlreadyInstalled)
    var isAppAlreadyInstalled: Bool = false
    @UserDefault(key: .isOnboardingDone)
    private var isOnboardingDone: Bool = false
    
    private var lastStatusTriggerOnWake: TimeInterval = 0.0
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        initAppearance()
        initUrlCache()
        LocalizationsManager.shared.start()
        PrivacyManager.shared.start()
        OrientationManager.shared.start()
        if isOnboardingDone {
            BluetoothStateManager.shared.start()
        }
        RBManager.shared.start(isFirstInstall: !isAppAlreadyInstalled,
                               server: Server(baseUrl: { Constant.Server.baseUrl },
                                              publicKey: Constant.Server.publicKey,
                                              certificateFile: Constant.Server.certificate,
                                              configUrl: Constant.Server.configUrl,
                                              configCertificateFile: Constant.Server.resourcesCertificate,
                                              deviceTimeNotAlignedToServerTimeDetected: {
                                    if UIApplication.shared.applicationState != .active {
                                        NotificationsManager.shared.triggerDeviceTimeErrorNotification()
                                    }
                               }),
                               storage: StorageManager(),
                               bluetooth: BluetoothManager(),
                               filter: FilteringManager(),
                               isAtRiskDidChangeHandler: { isAtRisk in
            if isAtRisk == true {
                NotificationsManager.shared.scheduleAtRiskNotification(minHour: ParametersManager.shared.minHourContactNotif, maxHour: ParametersManager.shared.maxHourContactNotif)
            }
        }, didStopProximityDueToLackOfEpochsHandler: {
            self.triggerStatusRequestIfNeeded()
            NotificationsManager.shared.triggerRestartNotification()
        }, didReceiveProximityHandler: {
            let nowTimestamp: TimeInterval = Date().timeIntervalSince1970
            guard nowTimestamp - self.lastStatusTriggerOnWake > 10.0 else { return }
            self.lastStatusTriggerOnWake = nowTimestamp
            self.triggerStatusRequestIfNeeded()
        })
        ParametersManager.shared.start()
        isAppAlreadyInstalled = true
        rootCoordinator.start()
        initAppMaintenance()
        return true
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        UIApplication.shared.clearBadge()
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        triggerStatusRequestIfNeeded { error in
            if let error = error, (error as NSError).code == -1 {
                NotificationsManager.shared.triggerDeviceTimeErrorNotification()
            }
        }
    }
    
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        triggerStatusRequestIfNeeded() { error in
            completionHandler(.newData)
        }
    }
    
    private func initAppearance() {
        UINavigationBar.appearance().tintColor = Asset.Colors.tint.color
    }
    
    private func initUrlCache() {
        URLCache.shared.diskCapacity = 0
        URLCache.shared.memoryCapacity = 0
        URLSession.shared.configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
    }
    
    private func initAppMaintenance() {
        MaintenanceManager.shared.start(coordinator: rootCoordinator)
    }

    private func triggerStatusRequestIfNeeded(completion: ((_ error: Error?) -> ())? = nil) {
        if RBManager.shared.isRegistered {
            let lastStatusRequestTimestamp: Double = RBManager.shared.lastStatusRequestDate?.timeIntervalSince1970 ?? 0.0
            let lastStatusSuccessTimestamp: Double = RBManager.shared.lastStatusReceivedDate?.timeIntervalSince1970 ?? 0.0
            let nowTimestamp: Double = Date().timeIntervalSince1970
            if nowTimestamp - lastStatusRequestTimestamp >= ParametersManager.shared.minStatusRetryTimeInterval && nowTimestamp - lastStatusSuccessTimestamp >= ParametersManager.shared.statusTimeInterval {
                RBManager.shared.status { error in
                    completion?(error)
                }
            } else {
                completion?(nil)
            }
        } else {
            completion?(nil)
        }
    }

}
