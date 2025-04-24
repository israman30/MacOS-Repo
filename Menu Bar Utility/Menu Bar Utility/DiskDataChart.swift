//
//  DiskDataChart.swift
//  Menu Bar Utility
//
//  Created by Israel Manzo on 4/24/25.
//

import SwiftUI
import Charts

struct DiskDataChart: View {
    var diskData: [FormattedDiskData]
    var body: some View {
        Chart(diskData) { info in
            SectorMark(
                angle: .value(info.title, info.percentage),
                innerRadius: .ratio(0.6),
                angularInset: 1.0
            )
            .foregroundStyle(
                by: .value(
                    Text(verbatim: info.title),
                    info.title
                )
            )
            .annotation(position: .overlay) {
                if info.title != "System" {
                    Text("\(info.percentage * 100, specifier: "%.1f%%")")
                        .bold()
                }
            }
            .cornerRadius(2)
        }
        .chartLegend(position: .trailing, alignment: .center)
    }
}

#Preview {
    DiskDataChart(diskData: FormattedDiskData.examples)
        .padding()
        .frame(width: 300, height: 300)
}
