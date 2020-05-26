// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  NotificationsManager.swift
//  STOP-COVID
//
//  Created by Lunabee Studio / Date - 09/04/2020 - for the STOP-COVID project.
//

import UIKit
import UserNotifications

final class NotificationsManager: NSObject, UNUserNotificationCenterDelegate {

    static let shared: NotificationsManager = NotificationsManager()

    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    func areNotificationsAuthorized(completion: ((_ authorized: Bool) -> ())? = nil) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion?(settings.alertSetting == .enabled)
            }
        }
    }

    func requestAuthorization(completion: ((_ granted: Bool) -> ())? = nil) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound], completionHandler: { (granted, _) in
            DispatchQueue.main.async {
                completion?(granted)
            }
        })
    }

    func isNotificationsStatusNotDetermined(completion: @escaping (_ notDetermined: Bool) -> ()) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus == .notDetermined)
            }
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .badge, .sound])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        if response.notification.request.identifier == "TestAtRiskNotification" {
            NotificationCenter.default.post(name: .didTouchAtRiskNotification, object: nil)
        }
        completionHandler()
    }
    
    func scheduleAtRiskNotification() {
        let content = UNMutableNotificationContent()
        content.title = "notification.atRisk.title".localized
        content.body = "notification.atRisk.message".localized
        content.sound = UNNotificationSound.default
        content.badge = 1
        let identifier: String = "TestAtRiskNotification"
        let request: UNNotificationRequest = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)
        requestAuthorization { _ in
            UNUserNotificationCenter.current().add(request) { _ in }
        }
    }
    
}
