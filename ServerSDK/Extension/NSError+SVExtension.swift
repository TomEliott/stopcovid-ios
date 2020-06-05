//
//  NSError+SVExtension.swift
//  ServerSDK
//
//  Created by Nicolas on 02/06/2020.
//  Copyright © 2020 Lunabee Studio. All rights reserved.
//

import UIKit

extension NSError {
    
    static func svLocalizedError(message: String, code: Int) -> Error {
        return NSError(domain: "Server-SDK", code: code, userInfo: [NSLocalizedDescriptionKey: message])
    }
    
}
