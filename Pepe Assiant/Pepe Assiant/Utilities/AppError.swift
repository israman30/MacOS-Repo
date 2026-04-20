import Foundation
import OSLog

/// A single, app-wide error type you can use across services, view models, and views.
enum AppError: Error, LocalizedError, Identifiable, Sendable, Equatable {
    case cancelled
    case permissionDenied(resource: String)
    case operationFailed(title: String, message: String, underlying: Underlying? = nil)
    case system(domain: String, code: Int, message: String)
    case unknown(message: String)
    
    struct Underlying: Sendable, Equatable {
        let domain: String
        let code: Int
        let message: String
    }
    
    var id: String {
        switch self {
        case .cancelled:
            return "cancelled"
        case .permissionDenied(let resource):
            return "permissionDenied:\(resource)"
        case .operationFailed(let title, let message, let underlying):
            if let underlying {
                return "operationFailed:\(title):\(message):\(underlying.domain):\(underlying.code)"
            }
            return "operationFailed:\(title):\(message)"
        case .system(let domain, let code, let message):
            return "system:\(domain):\(code):\(message)"
        case .unknown(let message):
            return "unknown:\(message)"
        }
    }
    
    var title: String {
        switch self {
        case .cancelled:
            return "Cancelled"
        case .permissionDenied:
            return "Permission needed"
        case .operationFailed(let title, _, _):
            return title
        case .system:
            return "Error"
        case .unknown:
            return "Error"
        }
    }
    
    var message: String {
        switch self {
        case .cancelled:
            return "The operation was cancelled."
        case .permissionDenied(let resource):
            return "NeatOS doesn’t have permission to access \(resource)."
        case .operationFailed(_, let message, let underlying):
            if let underlying, !underlying.message.isEmpty, underlying.message != message {
                return "\(message)\n\nDetails: \(underlying.message)"
            }
            return message
        case .system(_, _, let message):
            return message
        case .unknown(let message):
            return message
        }
    }
    
    var errorDescription: String? { message }
}

/// Central place to normalize arbitrary `Error` values into `AppError`.
enum ErrorHandler {
    static func toAppError(_ error: Error, title: String? = nil, context: String? = nil) -> AppError {
        if let appError = error as? AppError { return appError }
        if error is CancellationError { return .cancelled }
        
        let ns = error as NSError
        let underlying = AppError.Underlying(domain: ns.domain, code: ns.code, message: ns.localizedDescription)
        
        // Common "user cancelled" patterns.
        if ns.domain == NSCocoaErrorDomain, ns.code == NSUserCancelledError {
            return .cancelled
        }
        
        // Treat some URL errors as "cancelled" too (e.g. user dismissed auth dialogs).
        if ns.domain == NSURLErrorDomain, ns.code == URLError.cancelled.rawValue {
            return .cancelled
        }
        
        let finalTitle = title ?? "Error"
        
        // If the caller provided context, use it as the user-facing message unless it's empty.
        if let context, !context.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return .operationFailed(title: finalTitle, message: context, underlying: underlying)
        }
        
        return .operationFailed(title: finalTitle, message: ns.localizedDescription, underlying: underlying)
    }
    
    /// Converts a message into a structured `AppError`.
    static func message(_ message: String, title: String = "Error") -> AppError {
        .operationFailed(title: title, message: message, underlying: nil)
    }
    
    /// Best-effort logging that returns a normalized `AppError` you can surface in UI.
    @discardableResult
    static func log(_ error: Error, title: String? = nil, context: String? = nil, file: String = #fileID, line: Int = #line, function: String = #function) -> AppError {
        let appError = toAppError(error, title: title, context: context)
        let details = (error as NSError)
        AppLog.security.error("Error. file=\(file, privacy: .public) line=\(line, privacy: .public) fn=\(function, privacy: .public) title=\(appError.title, privacy: .public) msg=\(appError.message, privacy: .private(mask: .hash)) domain=\(details.domain, privacy: .public) code=\(details.code, privacy: .public)")
        return appError
    }
}

extension Error {
    var appError: AppError { ErrorHandler.toAppError(self) }
}
