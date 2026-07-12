import AppKit
import Darwin

/// libproc helpers for same-user process inspection.
enum ProcessUtils {
    static func parentPID(of pid: pid_t) -> pid_t? {
        var info = proc_bsdinfo()
        let size = Int32(MemoryLayout<proc_bsdinfo>.size)
        guard proc_pidinfo(pid, PROC_PIDTBSDINFO, 0, &info, size) == size else { return nil }
        return pid_t(info.pbi_ppid)
    }

    /// argv[0] via KERN_PROCARGS2 — the only reliable identity for the claude
    /// CLI, whose exec name is a bare version string (e.g. "2.1.207").
    static func argv0(of pid: pid_t) -> String? {
        var mib: [Int32] = [CTL_KERN, KERN_PROCARGS2, pid]
        var size = 0
        guard sysctl(&mib, 3, nil, &size, nil, 0) == 0, size > MemoryLayout<Int32>.size else {
            return nil
        }
        var buf = [UInt8](repeating: 0, count: size)
        guard sysctl(&mib, 3, &buf, &size, nil, 0) == 0 else { return nil }
        var i = MemoryLayout<Int32>.size
        while i < size, buf[i] != 0 { i += 1 } // skip exec path
        while i < size, buf[i] == 0 { i += 1 } // skip padding
        guard i < size else { return nil }
        let start = i
        while i < size, buf[i] != 0 { i += 1 }
        return String(bytes: buf[start..<i], encoding: .utf8)
    }

    static func hasControllingTerminal(_ pid: pid_t) -> Bool {
        var info = proc_bsdinfo()
        let size = Int32(MemoryLayout<proc_bsdinfo>.size)
        guard proc_pidinfo(pid, PROC_PIDTBSDINFO, 0, &info, size) == size else { return false }
        return info.pbi_flags & UInt32(PROC_FLAG_CONTROLT) != 0
    }

    static func path(of pid: pid_t) -> String? {
        var buf = [CChar](repeating: 0, count: 4096)
        guard proc_pidpath(pid, &buf, UInt32(buf.count)) > 0 else { return nil }
        return String(cString: buf)
    }

    static func cwd(of pid: pid_t) -> String? {
        var vinfo = proc_vnodepathinfo()
        let size = Int32(MemoryLayout<proc_vnodepathinfo>.size)
        guard proc_pidinfo(pid, PROC_PIDVNODEPATHINFO, 0, &vinfo, size) > 0 else { return nil }
        return withUnsafeBytes(of: vinfo.pvi_cdir.vip_path) { raw in
            raw.bindMemory(to: CChar.self).baseAddress.map { String(cString: $0) }
        }
    }

    static func startDate(of pid: pid_t) -> Date? {
        var info = proc_bsdinfo()
        let size = Int32(MemoryLayout<proc_bsdinfo>.size)
        guard proc_pidinfo(pid, PROC_PIDTBSDINFO, 0, &info, size) == size else { return nil }
        return Date(timeIntervalSince1970: TimeInterval(info.pbi_start_tvsec))
    }

    /// Walk up the parent chain to the nearest regular GUI app (Terminal, iTerm2, VS Code, …).
    static func nearestGUIApp(from pid: pid_t) -> pid_t? {
        var current = pid
        for _ in 0..<15 {
            if let app = NSRunningApplication(processIdentifier: current),
               app.activationPolicy == .regular {
                return current
            }
            guard let parent = parentPID(of: current), parent > 1, parent != current else {
                return nil
            }
            current = parent
        }
        return nil
    }

    /// Total CPU time (user+system, ns) — deltas between samples reveal activity.
    static func cpuTime(of pid: pid_t) -> UInt64? {
        var info = rusage_info_current()
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: rusage_info_t?.self, capacity: 1) {
                proc_pid_rusage(pid, RUSAGE_INFO_CURRENT, $0)
            }
        }
        guard result == 0 else { return nil }
        return info.ri_user_time &+ info.ri_system_time
    }

    static func allPIDs() -> [pid_t] {
        let count = proc_listallpids(nil, 0)
        guard count > 0 else { return [] }
        var pids = [pid_t](repeating: 0, count: Int(count) * 2)
        let filled = proc_listallpids(&pids, Int32(pids.count * MemoryLayout<pid_t>.size))
        guard filled > 0 else { return [] }
        return Array(pids.prefix(Int(filled)))
    }
}
