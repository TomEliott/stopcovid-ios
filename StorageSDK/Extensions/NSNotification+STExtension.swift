// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  NSNotification+STExtension.swift
//  STOP-COVID
//
//  Created by Lunabee Studio / Date - 14/04/2020 - for the STOP-COVID project.
//

import UIKit

public extension NSNotification.Name {
    
    static var statusDataDidChange: NSNotification.Name = NSNotification.Name(rawValue: "statusDataDidChange")
    static var localProximityDataDidChange: NSNotification.Name = NSNotification.Name(rawValue: "localProximityDataDidChange")
    
}
