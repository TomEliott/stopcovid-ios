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
    
    @UserDefault(key: .lastStatusBackgroundFetchTimestamp)
    private var lastStatusBackgroundFetchTimestamp: Double = 0.0
    @UserDefault(key: .lastStatusBackgroundFetchDidSucceed)
    private var lastStatusBackgroundFetchDidSucceed: Bool = false
    
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
                               server: Server(baseUrl: Constant.Server.baseUrl,
                                              publicKey: Constant.Server.publicKey,
                                              certificateFile: Constant.Server.certificate,
                                              configUrl: Constant.Server.configUrl),
                               storage: StorageManager(),
                               bluetooth: BluetoothManager(),
                               isAtRiskDidChangeHandler: { isAtRisk in
            if isAtRisk == true {
                NotificationsManager.shared.scheduleAtRiskNotification(minHour: ParametersManager.shared.minHourContactNotif, maxHour: ParametersManager.shared.maxHourContactNotif)
            }
        }, didStopProximityDueToLackOfEpochsHandler: {
            NotificationsManager.shared.triggerRestartNotification()
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
    
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        if RBManager.shared.isRegistered {
            RBManager.shared.status { error in
                self.lastStatusBackgroundFetchTimestamp = Date().timeIntervalSince1970
                self.lastStatusBackgroundFetchDidSucceed = error == nil
                completionHandler(error == nil ? .newData : .failed)
            }
        } else {
            lastStatusBackgroundFetchTimestamp = Date().timeIntervalSince1970
            lastStatusBackgroundFetchDidSucceed = true
            // This is done not to have a smaller background fetch requests frequency.
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

}
