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
        VStack {
            HStack {
                Text(info.title)
                Spacer()
                Text(info.formattedSize)
                    .font(.system(.body, design: .monospaced))
            }
            
            GeometryReader { geometry in
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                
                Rectangle()
                    .fill(proggresColor)
                    .frame(width: geometry.size.width * info.percentage)
            }
            .frame(height: 6)
            .clipShape(Capsule())
        }
    }
    
    var proggresColor: Color {
        switch info.title {
        case "System":
            return .blue
        case "Available":
            return .green
        default:
            return .orange
        }
    }
}

#Preview {
    DiskInfoRow(info: .example)
        .padding()
        .frame(width: 300, height: 100)
}
