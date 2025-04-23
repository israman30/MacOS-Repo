//
//  DiskData.swift
//  Menu Bar Utility
//
//  Created by Israel Manzo on 4/23/25.
//

import Foundation

struct DiskData {
    let fileSystemName: String
    let size: Int64
    let used: Int64
    let available: Int64
    let capcity: Int
    let mountPoint: String
    
    var isSystemVolume: Bool {
        mountPoint == "/"
    }
    
    var isDataVolume: Bool {
        fileSystemName == "/System/Volumes/Data"
    }
}

// MARK: - Data Analysis extension
extension Array where Element == DiskData {
    var systemVolume: DiskData? {
        first(where: \.isSystemVolume)
    }
    
    var dataVolume: DiskData? {
        first(where: \.isDataVolume)
    }
}
