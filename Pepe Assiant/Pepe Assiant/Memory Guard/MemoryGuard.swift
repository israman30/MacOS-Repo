//
//  MemoryGuard.swift
//  Pepe Assiant
//
//  Memory Guard: RAM optimization with hibernation, pressure alerts, and leak detection.
//

import Foundation
import AppKit
import Combine
import Darwin

// MARK: - Memory Pressure Level
enum MemoryPressureLevel: String, CaseIterable {
    case normal = "Normal"
    case warn = "Warning"
    case critical = "Critical"
    
    var color: (r: Double, g: Double, b: Double) {
        switch self {
        case .normal: return (0.2, 0.8, 0.4)
        case .warn: return (1.0, 0.7, 0.2)
        case .critical: return (1.0, 0.3, 0.2)
        }
    }
    
    var icon: String {
        switch self {
        case .normal: return "checkmark.circle.fill"
        case .warn: return "exclamationmark.triangle.fill"
        case .critical: return "xmark.octagon.fill"
        }
    }
}

// MARK: - Tracked Process (for leak detection)
struct TrackedProcess: Identifiable {
    let id: Int32
    let name: String
    let bundleIdentifier: String?
    var residentSize: UInt64
    var samples: [(Date, UInt64)]
    var isHibernated: Bool
    
    var formattedMemory: String {
        ByteCountFormatter.string(fromByteCount: Int64(residentSize), countStyle: .memory)
    }
    
    var growthRateMBPerMinute: Double? {
        guard samples.count >= 2 else { return nil }
        let sorted = samples.sorted { $0.0 < $1.0 }
        guard let first = sorted.first, let last = sorted.last else { return nil }
        let durationMinutes = last.0.timeIntervalSince(first.0) / 60
        guard durationMinutes > 0 else { return nil }
        let growthBytes = Double(last.1) - Double(first.1)
        return (growthBytes / 1_048_576) / durationMinutes
    }
}

// MARK: - Memory Guard Service
@MainActor
final class MemoryGuard: ObservableObject {
    
    // MARK: - Published State
    @Published var memoryPressureLevel: MemoryPressureLevel = .normal
    @Published var usedMemoryBytes: UInt64 = 0
    @Published var totalMemoryBytes: UInt64 = 0
    @Published var usedMemoryPercent: Double = 0
    @Published var showPressureAlert: Bool = false
    @Published var suspectedLeaks: [TrackedProcess] = []
    @Published var hibernatedApps: Set<Int32> = []
    @Published var isPurging: Bool = false
    @Published var lastPurgeDate: Date?
    
    // MARK: - Configuration
    private let hibernationIdleMinutes: Int = 30
    private let leakSampleIntervalSeconds: TimeInterval = 60
    private let leakGrowthThresholdMBPerMin: Double = 5.0
    private let pressureCheckInterval: TimeInterval = 5
    private let criticalFreePercentThreshold: Double = 5.0
    private let warnFreePercentThreshold: Double = 15.0
    
    private nonisolated(unsafe) var pressureCheckTimer: Timer?
    private nonisolated(unsafe) var leakSampleTimer: Timer?
    private nonisolated(unsafe) var hibernationTimer: Timer?
    private var processHistory: [Int32: [(Date, UInt64)]] = [:]
    private var lastFrontmostAppChange: Date = Date()
    private var lastFrontmostPID: Int32 = -1
    
    private let workspace = NSWorkspace.shared
    private let byteFormatter = ByteCountFormatter()
    
    init() {
        byteFormatter.countStyle = .memory
        refreshMemoryStats()
        startMonitoring()
    }
    
    deinit {
        stopMonitoring()
    }
    
    // MARK: - Public API
    
    func refreshMemoryStats() {
        let (used, total, level) = fetchMemoryStats()
        usedMemoryBytes = used
        totalMemoryBytes = total
        usedMemoryPercent = total > 0 ? (Double(used) / Double(total)) * 100 : 0
        memoryPressureLevel = level
        
        if level == .critical {
            showPressureAlert = true
        }
    }
    
    func oneTapPurge() {
        isPurging = true
        Task {
            await performPurge()
            await MainActor.run {
                isPurging = false
                lastPurgeDate = Date()
                refreshMemoryStats()
            }
        }
    }
    
    func suggestRestart(pid: Int32) {
        // User can quit/restart the app - we provide the suggestion
        // Could open Activity Monitor or show a dialog
        if let app = workspace.runningApplications.first(where: { $0.processIdentifier == pid }) {
            app.terminate()
        }
    }
    
    func hibernateApp(pid: Int32) -> Bool {
        let result = kill(pid, SIGSTOP)
        if result == 0 {
            hibernatedApps.insert(pid)
            return true
        }
        return false
    }
    
    func wakeApp(pid: Int32) -> Bool {
        let result = kill(pid, SIGCONT)
        if result == 0 {
            hibernatedApps.remove(pid)
            return true
        }
        return false
    }
    
    func dismissPressureAlert() {
        showPressureAlert = false
    }
    
    // MARK: - Memory Stats (host_statistics64 - works in sandbox)
    
    private func fetchMemoryStats() -> (used: UInt64, total: UInt64, level: MemoryPressureLevel) {
        var totalMem: UInt64 = 0
        var size = MemoryLayout<UInt64>.size
        sysctlbyname("hw.memsize", &totalMem, &size, nil, 0)
        
        let host = mach_host_self()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)
        var vmStats = vm_statistics64_data_t()
        
        let result = withUnsafeMutablePointer(to: &vmStats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(host, HOST_VM_INFO64, $0, &count)
            }
        }
        
        guard result == KERN_SUCCESS else {
            return (0, totalMem, .normal)
        }
        
        var pageSize: Int32 = 0
        var psize = MemoryLayout<Int32>.size
        sysctlbyname("hw.pagesize", &pageSize, &psize, nil, 0)
        let pageSizeUInt = UInt64(pageSize)
        
        let freePages = UInt64(vmStats.free_count)
        let activePages = UInt64(vmStats.active_count)
        let inactivePages = UInt64(vmStats.inactive_count)
        let wiredPages = UInt64(vmStats.wire_count)
        let compressedPages = UInt64(vmStats.compressor_page_count)
        
        let usedPages = activePages + inactivePages + wiredPages + compressedPages
        let usedBytes = usedPages * pageSizeUInt
        let freeBytes = freePages * pageSizeUInt
        let freePercent = totalMem > 0 ? (Double(freeBytes) / Double(totalMem)) * 100 : 0
        
        let level: MemoryPressureLevel
        if freePercent <= criticalFreePercentThreshold {
            level = .critical
        } else if freePercent <= warnFreePercentThreshold {
            level = .warn
        } else {
            level = .normal
        }
        
        return (usedBytes, totalMem, level)
    }
    
    // MARK: - Purge (sync + suggest closing apps)
    
    private func performPurge() async {
        // Sync to encourage macOS to reclaim inactive memory
        sync()
        // Small delay to let the system respond
        try? await Task.sleep(nanoseconds: 500_000_000)
    }
    
    // MARK: - Process Memory (proc_pidinfo)
    
    private func getResidentSize(pid: Int32) -> UInt64? {
        var info = proc_taskinfo()
        let size = proc_pidinfo(pid, PROC_PIDTASKINFO, 0, &info, Int32(MemoryLayout<proc_taskinfo>.size))
        guard size == MemoryLayout<proc_taskinfo>.size else { return nil }
        return info.pti_resident_size
    }
    
    // MARK: - Leak Detection
    
    private func sampleProcessMemory() {
        let apps = workspace.runningApplications
            .filter { $0.activationPolicy == .regular && $0.processIdentifier != -1 }
        
        for app in apps {
            let pid = app.processIdentifier
            guard let rss = getResidentSize(pid: pid) else { continue }
            
            var history = processHistory[pid] ?? []
            history.append((Date(), rss))
            if history.count > 10 {
                history.removeFirst()
            }
            processHistory[pid] = history
            
            let name = app.localizedName ?? "Unknown"
            let bundleId = app.bundleIdentifier
            let tracked = TrackedProcess(
                id: pid,
                name: name,
                bundleIdentifier: bundleId,
                residentSize: rss,
                samples: history,
                isHibernated: hibernatedApps.contains(pid)
            )
            
            if let growth = tracked.growthRateMBPerMinute, growth > leakGrowthThresholdMBPerMin {
                if !suspectedLeaks.contains(where: { $0.id == pid }) {
                    suspectedLeaks.append(tracked)
                } else if let idx = suspectedLeaks.firstIndex(where: { $0.id == pid }) {
                    suspectedLeaks[idx] = tracked
                }
            }
        }
        
        // Remove apps that are no longer running or no longer leaking
        suspectedLeaks = suspectedLeaks.filter { proc in
            apps.contains { $0.processIdentifier == proc.id }
        }
    }
    
    // MARK: - Hibernation (freeze background apps after 30 min)
    
    private func checkHibernationEligibility() {
        let frontmost = workspace.frontmostApplication?.processIdentifier ?? -1
        let now = Date()
        
        if frontmost != lastFrontmostPID {
            lastFrontmostPID = frontmost
            lastFrontmostAppChange = now
        }
        
        let apps = workspace.runningApplications
            .filter { app in
                app.activationPolicy == .regular
                && app.processIdentifier != -1
                && app.processIdentifier != ProcessInfo.processInfo.processIdentifier
                && !hibernatedApps.contains(app.processIdentifier)
            }
        
        for app in apps {
            let pid = app.processIdentifier
            if pid == frontmost { continue }
            
            // Consider "idle" if not frontmost for 30+ minutes
            // We use lastFrontmostAppChange as proxy - in reality we'd track per-app
            // For simplicity: hibernate any background app if we've been on current app 30+ min
            let idleMinutes = now.timeIntervalSince(lastFrontmostAppChange) / 60
            if Int(idleMinutes) >= hibernationIdleMinutes {
                _ = hibernateApp(pid: pid)
            }
        }
    }
    
    // MARK: - Monitoring
    
    private func startMonitoring() {
        pressureCheckTimer = Timer.scheduledTimer(withTimeInterval: pressureCheckInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refreshMemoryStats()
            }
        }
        pressureCheckTimer?.tolerance = 1
        RunLoop.current.add(pressureCheckTimer!, forMode: .common)
        
        leakSampleTimer = Timer.scheduledTimer(withTimeInterval: leakSampleIntervalSeconds, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.sampleProcessMemory()
            }
        }
        leakSampleTimer?.tolerance = 5
        RunLoop.current.add(leakSampleTimer!, forMode: .common)
        
        hibernationTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkHibernationEligibility()
            }
        }
        hibernationTimer?.tolerance = 10
        RunLoop.current.add(hibernationTimer!, forMode: .common)
        
        sampleProcessMemory()
    }
    
    nonisolated private func stopMonitoring() {
        pressureCheckTimer?.invalidate()
        pressureCheckTimer = nil
        leakSampleTimer?.invalidate()
        leakSampleTimer = nil
        hibernationTimer?.invalidate()
        hibernationTimer = nil
    }
}
