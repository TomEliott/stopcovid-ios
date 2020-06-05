//
//  FileManager+SVExtension.swift
//  ServerSDK
//
//  Created by Nicolas on 02/06/2020.
//  Copyright © 2020 Lunabee Studio. All rights reserved.
//

import Foundation

extension FileManager {
    
    class func svLibraryDirectory() -> URL {
        return try! FileManager.default.url(for: .libraryDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
    }
    
}
