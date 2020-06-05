//
//  Bundle+Extension.swift
//  StopCovid
//
//  Created by Nicolas on 04/06/2020.
//  Copyright © 2020 Lunabee Studio. All rights reserved.
//

import Foundation

extension Bundle {
    
    func fileDataFor(fileName: String, ofType: String) -> Data? {
        guard let filePath = path(forResource: fileName, ofType: "pem") else { return nil }
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: filePath)) else { return nil }
        return data
    }
    
}
