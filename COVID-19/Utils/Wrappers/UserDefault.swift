// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  UserDefault.swift
//  STOP-COVID
//
//  Created by Lunabee Studio / Date - 08/04/2019.
//

import UIKit

@propertyWrapper
final class UserDefault<T> {
    
    let defaults: UserDefaults = .standard
    let key: String
    let defaultValue: T
    
    var projectedValue: String { key }
    
    var wrappedValue: T {
        get { defaults.object(forKey: key) as? T ?? defaultValue }
        set {
            defaults.set(newValue, forKey: key)
            defaults.synchronize()
        }
    }

    init(wrappedValue: T, key: String) {
        self.defaultValue = wrappedValue
        self.key = key
    }
    
}
