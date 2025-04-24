//
//  ContentView.swift
//  Menu Bar Utility
//
//  Created by Israel Manzo on 4/23/25.
//

import SwiftUI

class DiscInformationFetch: ObservableObject {
    
    enum CommandError: Error {
        case invalidData
        case commandFailed(_ error: String)
        case emptyOutput
    }
    
    func execute(with command: String) throws -> String {
        let process = Process()
        let pipe = Pipe()
        
        process.launchPath = "/bin/sh"
        process.arguments = ["-c", command]
        process.standardOutput = pipe
        
        try? process.run()
        process.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        
        guard let output = String(data: data, encoding: .utf8) else {
            throw CommandError.invalidData
        }
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            throw CommandError.commandFailed(output)
        }
        return output
    }
    
    func parse(_ output: String) throws -> [DiskData] {
        let lines = output.components(separatedBy: .newlines)
        guard lines.count > 1 else {
            throw CommandError.emptyOutput
        }
        
        // Skip header line
        let dataLines = lines.dropFirst()
        
        return dataLines.compactMap { line -> DiskData? in
            let components = line.split(separator: "  ", omittingEmptySubsequences: true)
            guard components.count >= 5 else { return nil }
            
            return DiskData(
                fileSystemName: String(components[0]),
                size: Int64(components[1]) ?? 0,
                used: Int64(components[2]) ?? 0,
                available: Int64(components[3]) ?? 0,
                capcity: Int(components[4].replacingOccurrences(of: "%", with: "")) ?? 0,
                mountPoint: components[5...].joined(separator: " ")
            )
        }
    }
    
    func parseCapacity(_ info: [DiskData]) -> [FormattedDiskData] {
        var results = [FormattedDiskData]()
        let total = info.systemVolume?.size ?? 0
        
        if let systemVoluem = info.systemVolume {
            results.append(
                FormattedDiskData(title: "System", size: systemVoluem.used, totalsize: total)
            )
        }
        
        if let dataValume = info.systemVolume {
            results.append(
                FormattedDiskData(title: "Available", size: dataValume.available, totalsize: total)
            )
            results.append(
                FormattedDiskData(title: "User data", size: dataValume.used, totalsize: total)
            )
        }
        return results
    }
}

struct ContentView: View {
    
    @StateObject var fetcher = DiscInformationFetch()
    
    var body: some View {
        VStack {
            Button("Fetch") {
                let output = try? fetcher.execute(with: "df -k")
                print(output ?? "none")
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
