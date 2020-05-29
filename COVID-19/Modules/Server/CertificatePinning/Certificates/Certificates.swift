// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  Certificates.swift
//  STOP-COVID
//
//  Created by Lunabee Studio / Date - 12/05/2020 - for the STOP-COVID project.
//


import UIKit

enum Certificate {
    
    case apiProd
    case appProd
    
    func validateChallenge(_ challenge: URLAuthenticationChallenge, completion: @escaping (_ validated: Bool, _ credential: URLCredential?) -> ()) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust else {
            completion(false, nil)
            return
        }
        guard let serverTrust = challenge.protectionSpace.serverTrust else {
            completion(false, nil)
            return
        }
        guard let serverCertificate = SecTrustGetCertificateAtIndex(serverTrust, 0) else {
            completion(false, nil)
            return
        }
        
        let serverCertificateData: CFData = SecCertificateCopyData(serverCertificate)
        let data: UnsafePointer<UInt8> = CFDataGetBytePtr(serverCertificateData)
        let size: CFIndex = CFDataGetLength(serverCertificateData)
        let cert1Base64: String = Data(bytes: data, count: size).base64EncodedString()
        
        guard let cert2Base64 = self.fileBase64Content() else {
            completion(false, nil)
            return
        }
        let certificateIsValid: Bool = cert1Base64 == cert2Base64
        
        completion(certificateIsValid, URLCredential(trust: serverTrust))
    }
    
    private func fileName() -> String {
        switch self {
        case .apiProd:
            return "api.stopcovid.gouv.fr"
        case .appProd:
            return "app.stopcovid.gouv.fr"
        }
    }
    
    private func fileBase64Content() -> String? {
        guard let filePath = Bundle.main.path(forResource: fileName(), ofType: "pem") else { return nil }
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: filePath)) else { return nil }
        return String(data: data, encoding: .utf8)?.cleaningPEMStrings()
    }

}
