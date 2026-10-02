//
//  DiscoveryManagerMethodChannel.swift
//  google_cast
//
//  Created by LUIZ FELIPE ALVES LIMA on 30/06/22.
//

import Flutter
import Foundation
import GoogleCast

/// Flutter method channel for Google Cast device discovery operations
/// 
/// This class manages the discovery of Google Cast devices on the local network.
/// It implements the Google Cast discovery manager listener protocol to receive
/// updates about Cast device availability and communicates these updates back
/// to the Flutter side via method channels.
///
/// Key features:
/// - Automatic device discovery management
/// - Real-time device list updates to Flutter
/// - Device indexing for Flutter-side device selection
/// - Singleton pattern for consistent state management
///
/// The class maintains a dictionary of discovered devices indexed by their
/// discovery position, enabling Flutter to reference devices by index when
/// initiating Cast sessions.
///
/// - Author: LUIZ FELIPE ALVES LIMA
/// - Since: iOS 10.0+
class FGCDiscoveryManagerMethodChannel : UIResponder, GCKDiscoveryManagerListener, FlutterPlugin{
    
    // MARK: - Singleton Implementation
    
    /// Private initializer to enforce singleton pattern
    private override init() {
        
    }
    
    /// Shared singleton instance
    static private let _instance = FGCDiscoveryManagerMethodChannel.init()
    
    /// Public accessor for the singleton instance
    /// - Returns: The shared FGCDiscoveryManagerMethodChannel instance
    static var instance : FGCDiscoveryManagerMethodChannel {
        _instance
    }
    
    // MARK: - Properties
    
    /// Returns the discovery manager only after the Cast context has been initialized.
    ///
    /// Accessing `GCKCastContext.sharedInstance()` before initialization throws,
    /// so callers must guard through this helper when handling Flutter method calls.
    private func withDiscoveryManager(result: @escaping FlutterResult, _ body: (GCKDiscoveryManager) -> Void) {
        guard GCKCastContext.isSharedInstanceInitialized() else {
            result(FlutterError(
                code: "cast_context_not_initialized",
                message: "Google Cast context is not initialized. Call setSharedInstanceWithOptions before using discovery APIs.",
                details: nil
            ))
            return
        }

        body(GCKCastContext.sharedInstance().discoveryManager)
    }
    
    /// Whether Flutter should be sent the discovered devices. Cleared by
    /// `stopDiscovery` so Flutter sees an empty list once scanning stops.
    var listing = true
    
    /// Flutter method channel for communicating device discovery events
    /// Used to send device list updates back to the Flutter side
    var channel : FlutterMethodChannel?
    
    // MARK: - Flutter Plugin Registration
    
    /// Registers the discovery manager method channel with Flutter
    /// 
    /// Sets up the Flutter method channel for device discovery communication.
    /// The channel name is "google_cast.discovery_manager" and handles
    /// device discovery related method calls from Flutter.
    ///
    /// - Parameter registrar: The Flutter plugin registrar for method channel setup
    static func register(with registrar: FlutterPluginRegistrar) {
        
        instance.channel = FlutterMethodChannel.init(name: "google_cast.discovery_manager", binaryMessenger: registrar.messenger())
        
        registrar.addMethodCallDelegate(instance, channel: instance.channel!)
        
    }
    
    // MARK: - Flutter Method Call Handling
    
    /// Handles method calls from the Flutter side
    /// 
    /// Processes incoming method calls for device discovery operations.
    ///
    /// Supported methods:
    /// - `startDiscovery`: Starts or restarts active device scanning
    /// - `stopDiscovery`: Stops active device scanning
    /// - `isDiscoveryActiveForDeviceCategory`: Checks if discovery is active for a device category
    ///
    /// - Parameters:
    ///   - call: The Flutter method call
    ///   - result: Callback to return results to Flutter
    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        withDiscoveryManager(result: result) { discoveryManager in
            switch call.method {
            case "startDiscovery":
                SwiftGoogleCastPlugin.instance?.shouldResumeDiscoveryOnForeground = true
                discoveryManager.passiveScan = false
                listing = true
                if discoveryManager.discoveryState == .stopped {
                    discoveryManager.startDiscovery()
                }
                // Re-send current device list so Flutter gets immediate state
                didUpdateDeviceList()
                result(true)
            case "stopDiscovery":
                SwiftGoogleCastPlugin.instance?.shouldResumeDiscoveryOnForeground = false
                if discoveryManager.discoveryState == .running {
                    discoveryManager.stopDiscovery()
                }
                listing = false
                didUpdateDeviceList()
                result(true)
            case "isDiscoveryActiveForDeviceCategory":
                if let args = call.arguments as? Dictionary<String, Any>,
                   let deviceCategory = args["deviceCategory"] as? String {
                    let isActive = discoveryManager.isDiscoveryActive(forDeviceCategory: deviceCategory)
                    result(isActive)
                } else {
                    result(false)
                }
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }
    
    // MARK: - Google Cast Discovery Manager Listener
    
    /// Called when a Cast device is updated in the discovery list
    /// 
    /// This method is invoked by the Cast SDK when an existing device's
    /// information is updated (e.g., name change, capability updates).
    ///
    /// - Parameters:
    ///   - device: The updated Cast device
    ///   - index: The index position of the device in the discovery list
    public func didUpdate(_ device: GCKDevice, at index: UInt) {
        didUpdateDeviceList()
    }
    
    /// Called when a new Cast device is discovered
    /// 
    /// This method is invoked when a new Cast device becomes available
    /// on the network. The device is added to the internal devices dictionary.
    ///
    /// - Parameters:
    ///   - device: The newly discovered Cast device
    ///   - index: The index position assigned to the device
    public func didInsert(_ device: GCKDevice, at index: UInt) {
        didUpdateDeviceList()
    }
    
    /// Called when a Cast device is removed from discovery
    /// 
    /// This method is invoked when a Cast device is no longer available
    /// (e.g., device goes offline, network changes). The device is removed
    /// from the internal devices dictionary.
    ///
    /// - Parameters:
    ///   - device: The Cast device that was removed
    ///   - index: The index position of the removed device
    public func didRemove(_ device: GCKDevice, at index: UInt) {
        didUpdateDeviceList()
    }
    
    /// Called when the device list changes
    /// 
    /// This method is invoked whenever there are changes to the discovery
    /// device list. It sends the updated device list to Flutter via the
    /// method channel, allowing the Flutter side to update its UI accordingly.
    ///
    /// The device list is sorted by index and converted to a format suitable
    /// for Flutter consumption, with each device represented as a dictionary
    /// containing device information and its discovery index.
    public func didUpdateDeviceList() {
        var list: [Dictionary<String, Any>] = []
        if listing && GCKCastContext.isSharedInstanceInitialized() {
            let discoveryManager = GCKCastContext.sharedInstance().discoveryManager
            for index in 0..<discoveryManager.deviceCount {
                var dict = discoveryManager.device(at: index).toDict()
                dict["index"] = index
                list.append(dict)
            }
        }
        channel?.invokeMethod("onDevicesChanged", arguments: list)
    }
    
}
