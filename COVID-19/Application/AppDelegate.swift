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

@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate {

    private let rootCoordinator: RootCoordinator = RootCoordinator()
    
    @UserDefault(key: "isAppAlreadyInstalled")
    var isAppAlreadyInstalled: Bool = false
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        initAppearance()
        initUrlCache()
        LocalizationsManager.shared.start()
        PrivacyManager.shared.start()
        OrientationManager.shared.start()
        PKHUD.sharedHUD.gracePeriod = 0.2
        RBManager.shared.start(isFirstInstall: !isAppAlreadyInstalled, server: Server(), storage: StorageManager(), bluetooth: BluetoothManager(serviceUUID: BluetoothConstants.serviceUUID, characteristicUUID: BluetoothConstants.characteristicUUID))
        isAppAlreadyInstalled = true
        rootCoordinator.start()
        initAppMaintenance()
        initBackgroundFetch()
        return true
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
    
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        if RBManager.shared.isRegistered {
            RBManager.shared.status { error in
                completionHandler(error == nil ? .newData : .failed)
            }
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
    
    private func initBackgroundFetch() {
        UIApplication.shared.setMinimumBackgroundFetchInterval(ServerConstant.statusRequestFrequencyInHours * 60 * 60)
    }
    
    private func initAppMaintenance() {
        MaintenanceManager.shared.start(coordinator: rootCoordinator)
    }

}
