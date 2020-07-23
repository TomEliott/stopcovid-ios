// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  Constant.swift
//  STOP-COVID
//
//  Created by Lunabee Studio / Date - 08/04/2020 - for the STOP-COVID project.
//

import UIKit
import ServerSDK

enum Constant {
    
    static let defaultLanguageCode: String = "en"
    
    #if targetEnvironment(simulator)
    static let isSimulator: Bool = true
    #else
    static let isSimulator: Bool = false
    #endif
    
    enum Tab: Int, CaseIterable {
        case proximity
        case sick
        case sharing
    }
    
    enum Server {
        
        static var baseUrl: URL { URL(string: "https://api.stopcovid.gouv.fr/api/\(ParametersManager.shared.apiVersion.rawValue)")! }
        
        static let publicKey: Data = Data(base64Encoded: "MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEAc9IDt6qJq453SwyWPB94JaLB2VfTAcL43YVtMr3HhDCd22gKaQXIbX1d+tNhfvaKM51sxeaXziPjntUzbTNiw==")!
        
        static var certificate: Data { Bundle.main.fileDataFor(fileName: "api.stopcovid.gouv.fr", ofType: "pem") ?? Data() }
        
        static var resourcesCertificate: Data { Bundle.main.fileDataFor(fileName: "app.stopcovid.gouv.fr", ofType: "pem") ?? Data() }
        
        static let configUrl: URL = URL(string: "https://app.stopcovid.gouv.fr/json/version-22/config.json")!

    }
    
}

typealias JSON = [String: Any]
