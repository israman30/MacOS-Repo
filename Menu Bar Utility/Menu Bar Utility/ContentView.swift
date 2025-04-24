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
    
    @Published var diskInformation: [FormattedDiskData] = []
    @Published var error: Error?
    @Published var isLoading: Bool = false
    
    func getDiskInformation() async throws -> [FormattedDiskData] {
        try await Task.detached(priority: .userInitiated) {
            let output = try self.execute(with: "df -k -P")
            print("Output: \(output)")
            let info = try self.parse(output)
            print("Info: \(info)")
            let formattedDiskInfo = self.parseCapacity(info)
            
            print("Formatted Info: \(formattedDiskInfo.count)")
            return formattedDiskInfo
        }
        .value
    }
    
    func execute(with command: String) throws -> String {
        let process = Process()
        let pipe = Pipe()
        
        process.standardOutput = pipe
        process.standardError = pipe
        process.arguments = ["-c", command]
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        
        try? process.run()
//        process.waitUntilExit()
        
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
            let components = line.split(separator: " ", omittingEmptySubsequences: true)
            guard components.count >= 5 else { return nil }
            
            return DiskData(
                fileSystemName: String(components[0]),
                size: Int64(components[1]) ?? 0,
                used: Int64(components[2]) ?? 0,
                available: Int64(components[3]) ?? 0,
                capacity: Int(components[4].replacingOccurrences(of: "%", with: "")) ?? 0,
                mountPoint: components[5...].joined(separator: " ")
            )
        }
    }
    
    func parseCapacity(_ info: [DiskData]) -> [FormattedDiskData] {
        var results = [FormattedDiskData]()
        let total = info.systemVolume?.size ?? 0
        debugPrint("-->", total)
        let system = info.systemVolume?.used ?? 0
        results.append(
            FormattedDiskData(title: "System", size: system, totalsize: total)
        )
        
        let available = info.systemVolume?.available ?? 0
        results.append(
            FormattedDiskData(title: "Available", size: available, totalsize: total)
        )
        let userData = info.dataVolume?.used ?? 0
        results.append(
            FormattedDiskData(title: "User data", size: userData, totalsize: total)
        )
        
        return results
    }
}

struct ContentView: View {
    
    @StateObject var fetcher = DiscInformationFetch()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Disk Analyser")
                .font(.title2)
                .bold()
            
            DiskInfoListView(diskInfo: fetcher.diskInformation)
            DiskDataChart(diskData: fetcher.diskInformation)
//            Button("Fetch") {
//                let output = try? fetcher.execute(with: "df -k")
//                print(output ?? "none")
//            }
        }
        .padding()
        .task {
            await fetchInfoDisk()
        }
    }
    
    private func fetchInfoDisk() async {
        do {
            fetcher.diskInformation = try await fetcher.getDiskInformation()
        } catch {
            fetcher.error = error
        }
    }
}

#Preview {
    ContentView()
        .frame(width: 500)
}
