//
//  Logger.swift
//
//
//  Created by Jay Wilson on 2/19/24.
//

import Foundation
import Logging

public enum HippoLoggerCategory: String {
    case `default`
    case asset
}

extension Logger {
    private static let label = "Hippo"
    
    static let `default` = Logger(label: "\(label).\( HippoLoggerCategory.default.rawValue)")
    static let asset = Logger(label: "\(label).\( HippoLoggerCategory.asset.rawValue)")
}
