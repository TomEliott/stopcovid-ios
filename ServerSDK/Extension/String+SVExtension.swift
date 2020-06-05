//
//  String+SVExtension.swift
//  ServerSDK
//
//  Created by Nicolas on 02/06/2020.
//  Copyright © 2020 Lunabee Studio. All rights reserved.
//

import UIKit

extension String {
    
    func svCleaningPEMStrings() -> String {
        replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "-----BEGIN EC PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "-----END EC PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "-----BEGIN PUBLIC KEY-----", with: "")
            .replacingOccurrences(of: "-----END PUBLIC KEY-----", with: "")
            .replacingOccurrences(of: "-----BEGIN CERTIFICATE-----", with: "")
            .replacingOccurrences(of: "-----END CERTIFICATE-----", with: "")
    }
    
}
