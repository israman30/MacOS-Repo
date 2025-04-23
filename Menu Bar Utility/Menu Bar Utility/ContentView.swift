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
