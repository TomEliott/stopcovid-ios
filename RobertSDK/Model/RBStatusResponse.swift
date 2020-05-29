//
//  RBStatusResponse.swift
//  STOP-COVID
//
//  Created by Lunabee Studio / Date - 29/04/2020 - for the STOP-COVID project.
//

import UIKit

public struct RBStatusResponse {

    let atRisk: Bool
    let lastExposureTimeFrame: Int?
    let tuples: String
    
    public init(atRisk: Bool, lastExposureTimeFrame: Int?, tuples: String) {
        self.atRisk = atRisk
        self.lastExposureTimeFrame = lastExposureTimeFrame
        self.tuples = tuples
    }
    
}
