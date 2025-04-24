//
//  DiskInfoRow.swift
//  Menu Bar Utility
//
//  Created by Israel Manzo on 4/23/25.
//

import SwiftUI

struct DiskInfoRow: View {
    
    let info: FormattedDiskData
    
    var body: some View {
        HStack {
            Text(info.title)
            Text(info.formattedSize)
        }
    }
}

#Preview {
    DiskInfoRow(info: .exmaple)
        .padding()
        .frame(width: 300, height: 100)
}
