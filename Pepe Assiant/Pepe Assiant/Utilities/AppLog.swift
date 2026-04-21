import Foundation
import OSLog

enum AppLog {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "PepeAssiant"
    
    static let security = Logger(subsystem: subsystem, category: "security")
    static let fileAccess = Logger(subsystem: subsystem, category: "file_access")
    static let fileOps = Logger(subsystem: subsystem, category: "file_ops")
}

