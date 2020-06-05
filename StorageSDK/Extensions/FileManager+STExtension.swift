//
//  FileManager+STExtension.swift
//  StorageSDK
//
//  Created by Nicolas on 01/06/2020.
//  Copyright © 2020 Lunabee Studio. All rights reserved.
//

import Foundation

extension FileManager {
    
    class func stLibraryDirectory() -> URL {
        return try! FileManager.default.url(for: .libraryDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
    }
    
}
