import Combine
import CoreAudio
import Foundation

/// System-wide mic control: mutes the default input device at the CoreAudio
/// level, so every app (Slack, Meet, Zoom, …) goes silent at once.
final class AudioManager: ObservableObject {
    @Published private(set) var isMuted = false
    @Published private(set) var micInUse = false
    @Published private(set) var deviceName = "No input device"

    private var deviceID = AudioObjectID(kAudioObjectUnknown)
    private var savedVolume: Float32?
    private var deviceListener: AudioObjectPropertyListenerBlock?

    init() {
        var addr = Self.address(kAudioHardwarePropertyDefaultInputDevice)
        AudioObjectAddPropertyListenerBlock(
            AudioObjectID(kAudioObjectSystemObject), &addr, DispatchQueue.main
        ) { [weak self] _, _ in
            self?.attachToDefaultDevice()
        }
        attachToDefaultDevice()
    }

    func toggleMute() {
        setMuted(!isMuted)
    }

    func setMuted(_ mute: Bool) {
        guard deviceID != kAudioObjectUnknown else { return }
        var muteAddr = Self.address(kAudioDevicePropertyMute, scope: kAudioDevicePropertyScopeInput)
        var settable: DarwinBoolean = false
        AudioObjectIsPropertySettable(deviceID, &muteAddr, &settable)
        if AudioObjectHasProperty(deviceID, &muteAddr), settable.boolValue {
            var value: UInt32 = mute ? 1 : 0
            AudioObjectSetPropertyData(deviceID, &muteAddr, 0, nil,
                                       UInt32(MemoryLayout<UInt32>.size), &value)
        } else {
            // ponytail: volume-0 fallback for mics without a hardware mute control
            if mute {
                savedVolume = Self.readInputVolume(deviceID)
                Self.writeInputVolume(deviceID, 0)
            } else {
                Self.writeInputVolume(deviceID, savedVolume ?? 0.75)
                savedVolume = nil
            }
        }
        refreshState()
    }

    // MARK: - Device tracking

    private func attachToDefaultDevice() {
        if deviceID != kAudioObjectUnknown, let listener = deviceListener {
            var muteAddr = Self.address(kAudioDevicePropertyMute, scope: kAudioDevicePropertyScopeInput)
            var runAddr = Self.address(kAudioDevicePropertyDeviceIsRunningSomewhere)
            AudioObjectRemovePropertyListenerBlock(deviceID, &muteAddr, DispatchQueue.main, listener)
            AudioObjectRemovePropertyListenerBlock(deviceID, &runAddr, DispatchQueue.main, listener)
        }
        deviceID = Self.defaultInputDevice()
        savedVolume = nil
        guard deviceID != kAudioObjectUnknown else {
            deviceName = "No input device"
            isMuted = false
            micInUse = false
            return
        }
        deviceName = Self.name(of: deviceID) ?? "Microphone"

        let listener: AudioObjectPropertyListenerBlock = { [weak self] _, _ in
            self?.refreshState()
        }
        deviceListener = listener
        var muteAddr = Self.address(kAudioDevicePropertyMute, scope: kAudioDevicePropertyScopeInput)
        if AudioObjectHasProperty(deviceID, &muteAddr) {
            AudioObjectAddPropertyListenerBlock(deviceID, &muteAddr, DispatchQueue.main, listener)
        }
        var runAddr = Self.address(kAudioDevicePropertyDeviceIsRunningSomewhere)
        AudioObjectAddPropertyListenerBlock(deviceID, &runAddr, DispatchQueue.main, listener)
        refreshState()
    }

    private func refreshState() {
        guard deviceID != kAudioObjectUnknown else { return }
        var muteAddr = Self.address(kAudioDevicePropertyMute, scope: kAudioDevicePropertyScopeInput)
        if AudioObjectHasProperty(deviceID, &muteAddr) {
            isMuted = Self.readUInt32(deviceID, &muteAddr) == 1
        } else {
            isMuted = (Self.readInputVolume(deviceID) ?? 1) == 0
        }
        var runAddr = Self.address(kAudioDevicePropertyDeviceIsRunningSomewhere)
        micInUse = Self.readUInt32(deviceID, &runAddr) != 0
    }

    // MARK: - CoreAudio helpers

    private static func address(
        _ selector: AudioObjectPropertySelector,
        scope: AudioObjectPropertyScope = kAudioObjectPropertyScopeGlobal,
        element: AudioObjectPropertyElement = kAudioObjectPropertyElementMain
    ) -> AudioObjectPropertyAddress {
        AudioObjectPropertyAddress(mSelector: selector, mScope: scope, mElement: element)
    }

    private static func defaultInputDevice() -> AudioObjectID {
        var addr = address(kAudioHardwarePropertyDefaultInputDevice)
        var device = AudioObjectID(kAudioObjectUnknown)
        var size = UInt32(MemoryLayout<AudioObjectID>.size)
        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject), &addr, 0, nil, &size, &device)
        return status == noErr ? device : AudioObjectID(kAudioObjectUnknown)
    }

    private static func name(of device: AudioObjectID) -> String? {
        var addr = address(kAudioObjectPropertyName)
        var name: Unmanaged<CFString>?
        var size = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
        guard AudioObjectGetPropertyData(device, &addr, 0, nil, &size, &name) == noErr else {
            return nil
        }
        return name?.takeRetainedValue() as String?
    }

    private static func readUInt32(_ device: AudioObjectID,
                                   _ addr: inout AudioObjectPropertyAddress) -> UInt32 {
        var value: UInt32 = 0
        var size = UInt32(MemoryLayout<UInt32>.size)
        guard AudioObjectGetPropertyData(device, &addr, 0, nil, &size, &value) == noErr else {
            return 0
        }
        return value
    }

    private static func volumeAddresses(_ device: AudioObjectID) -> [AudioObjectPropertyAddress] {
        [0, 1, 2].compactMap { element in
            var addr = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyVolumeScalar,
                mScope: kAudioDevicePropertyScopeInput,
                mElement: AudioObjectPropertyElement(element))
            return AudioObjectHasProperty(device, &addr) ? addr : nil
        }
    }

    private static func readInputVolume(_ device: AudioObjectID) -> Float32? {
        for var addr in volumeAddresses(device) {
            var volume: Float32 = 0
            var size = UInt32(MemoryLayout<Float32>.size)
            if AudioObjectGetPropertyData(device, &addr, 0, nil, &size, &volume) == noErr {
                return volume
            }
        }
        return nil
    }

    private static func writeInputVolume(_ device: AudioObjectID, _ value: Float32) {
        for var addr in volumeAddresses(device) {
            var volume = value
            AudioObjectSetPropertyData(device, &addr, 0, nil,
                                       UInt32(MemoryLayout<Float32>.size), &volume)
        }
    }
}
