//
//  DiskData.swift
//  Menu Bar Utility
//
//  Created by Israel Manzo on 4/23/25.
//

import Foundation

struct FormattedDiskData: Identifiable {
    let id = UUID()
    let title: String
    let size: Int64
    let totalsize: Int64
}

struct DiskData {
    let fileSystemName: String
    let size: Int64
    let used: Int64
    let available: Int64
    let capacity: Int
    let mountPoint: String
    
    var isSystemVolume: Bool {
        mountPoint == "/"
    }
    
    var isDataVolume: Bool {
        mountPoint == "/System/Volumes/Data"
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
