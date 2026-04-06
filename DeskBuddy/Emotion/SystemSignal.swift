// DeskBuddy/Emotion/SystemSignal.swift
import Foundation
import CoreGraphics
import Darwin

struct SystemSignal {
    static func score(cpuUsage: Double, memoryPressure: Double, idleMinutes: Int) -> Double {
        var s = 0.6
        if cpuUsage > 0.8 { s -= 0.4 }
        else if cpuUsage < 0.2 { s -= 0.2 }
        if memoryPressure > 0.8 { s -= 0.3 }
        if idleMinutes > 45 { s -= 0.2 }
        return max(0, min(1, s))
    }

    static func currentCPUUsage() -> Double {
        var info = host_cpu_load_info()
        var count = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info>.size / MemoryLayout<integer_t>.size)
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return 0.3 }
        let total = Double(info.cpu_ticks.0 + info.cpu_ticks.1 + info.cpu_ticks.2 + info.cpu_ticks.3)
        let idle = Double(info.cpu_ticks.3)
        return total > 0 ? 1.0 - (idle / total) : 0.3
    }

    static func currentMemoryPressure() -> Double {
        // kern.memorystatus_level: 100=充裕, ~25=warning, ~5=critical
        var level: Int32 = 100
        var size = MemoryLayout<Int32>.size
        sysctlbyname("kern.memorystatus_level", &level, &size, nil, 0)
        return 1.0 - (Double(max(0, min(100, level))) / 100.0)
    }

    static func currentIdleMinutes() -> Int {
        let idleSeconds = CGEventSource.secondsSinceLastEventType(
            .combinedSessionState,
            eventType: CGEventType(rawValue: ~0)!
        )
        return Int(idleSeconds / 60)
    }
}
