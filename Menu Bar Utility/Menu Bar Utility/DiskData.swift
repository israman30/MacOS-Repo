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
    
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size * 1024, countStyle: .file)
    }
    
    var formattedTotalSize: String {
        ByteCountFormatter.string(fromByteCount: totalsize * 1024, countStyle: .file)
    }
    
    var percentage: Double {
        Double(size) / Double(totalsize)
    }
    
    static var example: FormattedDiskData {
        .init(title: "System", size: 11 * 1024, totalsize: 910 * 1024)
    }
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
