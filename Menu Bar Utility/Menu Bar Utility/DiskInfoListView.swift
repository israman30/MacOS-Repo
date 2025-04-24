//
//  DiskInfoListView.swift
//  Menu Bar Utility
//
//  Created by Israel Manzo on 4/23/25.
//

import SwiftUI

struct DiskInfoListView: View {
    var diskInfo: [FormattedDiskData]
    var body: some View {
        List(diskInfo) { info in
            DiskInfoRow(info: info)
        }
    }
}

#Preview {
    DiskInfoListView(diskInfo: [.exmaple])
}
