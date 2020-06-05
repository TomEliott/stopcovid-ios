//
//  URL+STExtension.swift
//  StorageSDK
//
//  Created by Nicolas on 01/06/2020.
//  Copyright © 2020 Lunabee Studio. All rights reserved.
//

import Foundation

extension URL {
    
    mutating func stAddSkipBackupAttribute() throws {
        var values: URLResourceValues = URLResourceValues()
        values.isExcludedFromBackup = true
        try setResourceValues(values)
    }
    
}
