import Combine
import CoreMediaIO
import Foundation

/// Live "camera in use" indicator. macOS offers no supported way to force-off
/// the camera for other apps (that needs a CMIO extension — phase 2), so this
/// reports honest status instead of a fake toggle.
final class CameraMonitor: ObservableObject {
    @Published private(set) var cameraInUse = false

    private var timer: Timer?

    init() {
        poll()
        // ponytail: 1.5s polling; switch to CMIO property listeners if latency matters
        timer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            self?.poll()
        }
    }

    deinit {
        timer?.invalidate()
    }

    private func poll() {
        guard Pref.enabled(Pref.cameraIndicator) else {
            if cameraInUse { cameraInUse = false }
            return
        }
        let running = Self.anyCameraRunning()
        if running != cameraInUse {
            cameraInUse = running
        }
    }

    private static func anyCameraRunning() -> Bool {
        cameraDevices().contains { isRunningSomewhere($0) }
    }

    private static func cameraDevices() -> [CMIOObjectID] {
        var addr = CMIOObjectPropertyAddress(
            mSelector: CMIOObjectPropertySelector(kCMIOHardwarePropertyDevices),
            mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
            mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain))
        var size: UInt32 = 0
        guard CMIOObjectGetPropertyDataSize(
            CMIOObjectID(kCMIOObjectSystemObject), &addr, 0, nil, &size) == noErr, size > 0
        else { return [] }
        var ids = [CMIOObjectID](repeating: 0, count: Int(size) / MemoryLayout<CMIOObjectID>.size)
        var used: UInt32 = 0
        guard CMIOObjectGetPropertyData(
            CMIOObjectID(kCMIOObjectSystemObject), &addr, 0, nil, size, &used, &ids) == noErr
        else { return [] }
        return ids
    }

    private static func isRunningSomewhere(_ device: CMIOObjectID) -> Bool {
        var addr = CMIOObjectPropertyAddress(
            mSelector: CMIOObjectPropertySelector(kCMIODevicePropertyDeviceIsRunningSomewhere),
            mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
            mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain))
        var running: UInt32 = 0
        var used: UInt32 = 0
        guard CMIOObjectGetPropertyData(
            device, &addr, 0, nil, UInt32(MemoryLayout<UInt32>.size), &used, &running) == noErr
        else { return false }
        return running != 0
    }
}
