//
//  SessionManagerMethodChannel.swift
//  google_cast
//
//  Created by LUIZ FELIPE ALVES LIMA on 23/06/22.
//

import Flutter
import Foundation
import GoogleCast

/// Flutter method channel for Google Cast session management operations
/// 
/// This class manages Google Cast sessions, handling the connection and disconnection
/// to Cast devices, session state monitoring, and device control operations.
/// It implements the Google Cast session manager listener protocol to receive
/// session-related events and communicates these back to Flutter.
///
/// Key features:
/// - Cast session creation and termination
/// - Session state monitoring and event handling
/// - Device volume control during active sessions
/// - Real-time session updates to Flutter
/// - Singleton pattern for consistent session state
///
/// The class provides a bridge between Flutter's session management API
/// and the native Google Cast SDK session functionality on iOS.
///
/// - Author: LUIZ FELIPE ALVES LIMA
/// - Since: iOS 10.0+
public class FGCSessionManagerMethodChannel : UIResponder, FlutterPlugin, GCKSessionManagerListener {
    
    // MARK: - Singleton Implementation
    
    /// Private initializer to enforce singleton pattern
    private override init() {
        
    }
    
    /// Shared singleton instance
    static private let _instance = FGCSessionManagerMethodChannel()
    
    /// Public accessor for the singleton instance
    /// - Returns: The shared FGCSessionManagerMethodChannel instance
    static public var instance : FGCSessionManagerMethodChannel{
         _instance
    }
    
    // MARK: - Google Cast Session Properties
    
    /// The current active Cast session (if any)
    /// - Returns: The current session or nil if no session is active
    var currentSession : GCKSession? {
        sessionManager.currentSession
    }
    
    /// The current active Cast session specifically (more specific than currentSession)
    /// - Returns: The current Cast session or nil if no Cast session is active
    var currentCastSession: GCKCastSession? {
        sessionManager.currentCastSession
    }
    
    /// The current connection state of the session manager
    /// - Returns: The connection state (disconnected, connecting, connected, etc.)
    var connectState: GCKConnectionState{
        sessionManager.connectionState
    }
    
    // MARK: - Communication Properties
    
    /// Flutter method channel for session management communication
    /// Used to send session events and handle method calls from Flutter
    var channel : FlutterMethodChannel?
    
    /// Tracks the last emitted connection state to deduplicate events.
    /// iOS Cast SDK fires multiple delegate callbacks (for both GCKSession
    /// and GCKCastSession) with the same connection state in rapid succession,
    /// causing event spam on the Flutter side.
    private var _lastEmittedConnectionState: GCKConnectionState?
    
    /// Reference to the Google Cast session manager
    /// - Returns: The session manager from the shared Cast context
    private var sessionManager : GCKSessionManager  {
        GCKCastContext.sharedInstance().sessionManager
    }
    
    /// Reference to the Google Cast discovery manager
    /// Used for device selection when starting sessions
    /// - Returns: The discovery manager from the shared Cast context
    private var discoveryManager: GCKDiscoveryManager  {
        GCKCastContext.sharedInstance().discoveryManager
    }
    
    // MARK: - Flutter Plugin Registration
        /// Registers the session manager method channel with Flutter
    /// 
    /// Sets up the Flutter method channel for session management communication.
    /// The channel name is "google_cast.session_manager" and handles all
    /// session-related method calls from Flutter.
    ///
    /// - Parameter registrar: The Flutter plugin registrar for method channel setup
    public static func register(with registrar: FlutterPluginRegistrar) {
        
        let instance = FGCSessionManagerMethodChannel.instance
        
        instance.channel =  FlutterMethodChannel(name: "google_cast.session_manager", binaryMessenger: registrar.messenger())
        
        registrar.addMethodCallDelegate(instance, channel: instance.channel!)
    }
    
    // MARK: - Flutter Method Call Handling
    
    /// Handles method calls from the Flutter side
    /// 
    /// Processes incoming method calls for session management operations.
    /// Each method corresponds to a specific Cast session operation.
    ///
    /// Supported methods:
    /// - `startSessionWithDevice`: Initiates a Cast session with a specific device
    /// - `endSession`: Terminates the current Cast session
    /// - `endSessionAndStopCasting`: Terminates session and stops casting
    /// - `setDeviceVolume`: Adjusts the volume of the connected Cast device
    ///
    /// - Parameters:
    ///   - call: The Flutter method call containing method name and arguments
    ///   - result: Callback to return results or errors to Flutter
   public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "startSessionWithDevice":
            result(startSessionWithDevice(deviceID: call.arguments as? String ?? ""))
            break
        case "endSession":
            endSession(result)
            break
        case "endSessionAndStopCasting":
            endSessionAndStopCasting(result)
            break
        case "resetSession":
            resetSession(result)
            break
        case "setDeviceVolume":
            setDeviceVolume(call.arguments as! NSNumber)
            break
            
        default:
            result(FlutterError(code: "METHOD_NOT_IMPLEMENTED", 
                               message: "No handler for method: \(call.method)", 
                               details: nil))
            break
        }
    }
    
    // MARK: - Cast Session Management Methods
    
    /// Initiates a Cast session with the specified device
    /// 
    /// Attempts to start a Cast session with a device from the discovery list.
    /// The device is identified by its index in the discovery manager's device list.
    ///
    /// - Parameter deviceIndex: The index of the device in the discovery list
    /// - Returns: `true` if session initiation was successful, `false` otherwise
    /// - Note: This method only initiates the session; actual connection status
    ///         is reported through session manager listener callbacks
    ///
    /// The index is bounds-checked against `GCKDiscoveryManager.deviceCount`
    /// before accessing the underlying device. `GCKDiscoveryManager.device(at:)`
    /// is backed by an `NSArray` and throws `NSRangeException` for out-of-bounds
    /// access, which crashes the process (Swift cannot catch Obj-C exceptions).
    /// The index comes from the Dart side, which holds a snapshot of the device
    /// list received via `onDevicesChanged`; between that snapshot and this
    /// call a device may disappear from the live discovery list (flaky
    /// receivers, network hiccups), making the snapshot index stale.
    private func startSessionWithDevice(deviceID : String) -> Bool {
        for index in 0..<discoveryManager.deviceCount {
            let device = discoveryManager.device(at: index)
            if device.deviceID == deviceID {
                return sessionManager.startSession(with: device)
            }
        }
        return false
    }
    
    /// Ends the current Cast session
    /// 
    /// Terminates the active Cast session if one exists. The session will be
    /// gracefully closed, but casting may continue on the receiver device.
    ///
    /// - Parameter result: Flutter result callback for operation status
    private func endSession(_ result : FlutterResult) {
        let success = self.sessionManager.endSession()
        result(success)
    }
    
    /// Ends the current session and stops casting on the receiver
    /// 
    /// Terminates the active Cast session and instructs the receiver device
    /// to stop casting entirely. This is more aggressive than `endSession()`.
    ///
    /// - Parameter result: Flutter result callback for operation status
    /// Ends the current session and stops casting on the receiver
    /// 
    /// Terminates the active Cast session and instructs the receiver device
    /// to stop casting entirely. This is more aggressive than `endSession()`.
    ///
    /// - Parameter result: Flutter result callback for operation status
    private func endSessionAndStopCasting(_ result : FlutterResult) {
        let success = self.sessionManager.endSessionAndStopCasting(true)
        result(success)
    }
    
    /// Sets the volume level of the connected Cast device
    /// 
    /// Adjusts the volume of the Cast receiver device during an active session.
    /// This controls the device's output volume, not the sender app's volume.
    ///
    /// - Parameter volume: The desired volume level (typically 0.0 to 1.0)
    /// - Note: Only works when there's an active Cast session
    func setDeviceVolume(_ volume : NSNumber){
        sessionManager.currentCastSession?.setDeviceVolume(Float(truncating: volume))
    }
    
    // MARK: - Google Cast Session Manager Listener
    
    /// Called when a session is about to start
    /// 
    /// This delegate method is invoked just before a Cast session begins.
    /// Updates Flutter with the new session state.
    ///
    /// - Parameters:
    ///   - sessionManager: The session manager instance
    ///   - session: The session that will start
    public func sessionManager(_ sessionManager: GCKSessionManager, willStart session: GCKSession) {
        onSessionChanged(session)
    }
    
    /// Called when a session has successfully started
    /// 
    /// This delegate method is invoked after a Cast session has been established.
    /// Notifies Flutter of the new session and starts media client listening.
    ///
    /// - Parameters:
    ///   - sessionManager: The session manager instance
    ///   - session: The session that started
    public func sessionManager(_ sessionManager: GCKSessionManager, didStart session: GCKSession) {
        onSessionChanged(session)
        RemoteMediaClienteMethodChannel.instance.startListen()
    }
    
    /// Called when a Cast session is about to start
    /// 
    /// This delegate method is invoked just before a Cast session begins.
    /// This is the Cast-specific version of willStart for GCKSession.
    ///
    /// - Parameters:
    ///   - sessionManager: The session manager instance
    ///   - session: The Cast session that will start
    public func sessionManager(_ sessionManager: GCKSessionManager, willStart session: GCKCastSession) {
        onSessionChanged(session)
    }
    
    /// Called when a Cast session fails to start
    /// 
    /// This delegate method is invoked when a Cast session initiation fails.
    /// Updates Flutter with the session state and error information.
    ///
    /// - Parameters:
    ///   - sessionManager: The session manager instance
    ///   - session: The Cast session that failed to start
    ///   - error: The error that caused the failure
    public func sessionManager(_ sessionManager: GCKSessionManager, didFailToStart session: GCKCastSession, withError error: Error) {
        onSessionChanged(session)
    }
    
    /// Called when a session is about to end
    /// 
    /// This delegate method is invoked just before a session terminates.
    /// Forces `disconnecting` state emission because iOS GCK SDK may set
    /// `session.connectionState` to `.disconnected` before calling `willEnd`,
    /// causing the Dart side to never see the `disconnecting` transition.
    ///
    /// - Parameters:
    ///   - sessionManager: The session manager instance
    ///   - session: The session that will end
    public func sessionManager(_ sessionManager: GCKSessionManager, willEnd session: GCKSession) {
        emitDisconnecting(session)
    }
    
    /// Called when a session has ended
    /// 
    /// This delegate method is invoked after a session has been terminated.
    /// Notifies Flutter and stops media client listening.
    ///
    /// - Parameters:
    ///   - sessionManager: The session manager instance
    ///   - session: The session that ended
    ///   - error: Optional error if the session ended unexpectedly
    public func sessionManager(_ sessionManager: GCKSessionManager, didEnd session: GCKSession, withError error: Error?) {
        onSessionChanged(session)
        RemoteMediaClienteMethodChannel.instance.onSessionEnd()
    }
    
    /// Called when a Cast session is about to end
    /// 
    /// This delegate method is invoked just before a Cast session terminates.
    /// Forces `disconnecting` state emission — same rationale as `willEnd`
    /// for `GCKSession`.
    ///
    /// - Parameters:
    ///   - sessionManager: The session manager instance
    ///   - session: The Cast session that will end
    public func sessionManager(_ sessionManager: GCKSessionManager, willEnd session: GCKCastSession) {
        emitDisconnecting(session)
    }
    
    /// Called when a Cast session has ended
    /// 
    /// This delegate method is invoked after a Cast session has been terminated.
    /// Clears the session state in Flutter and stops media client operations.
    ///
    /// - Parameters:
    ///   - sessionManager: The session manager instance
    ///   - session: The Cast session that ended
    ///   - error: Optional error if the session ended unexpectedly
    public func sessionManager(_ sessionManager: GCKSessionManager, didEnd session: GCKCastSession, withError error: Error?) {
        onSessionChanged(nil)
        RemoteMediaClienteMethodChannel.instance.onSessionEnd()
    }
    
    /// Called when a session fails to start
    /// 
    /// This delegate method is invoked when a session initiation fails.
    /// Updates Flutter with the session state and error information.
    ///
    /// - Parameters:
    ///   - sessionManager: The session manager instance
    ///   - session: The session that failed to start
    ///   - error: The error that caused the failure
    public func sessionManager(_ sessionManager: GCKSessionManager, didFailToStart session: GCKSession, withError error: Error) {
        onSessionChanged(session)
    }
    
    /// Called when a session is suspended
    /// 
    /// This delegate method is invoked when a session is temporarily suspended
    /// (e.g., app goes to background). Clears the session state in Flutter.
    ///
    /// - Parameters:
    ///   - sessionManager: The session manager instance
    ///   - session: The session that was suspended
    ///   - reason: The reason for the suspension
    public func sessionManager(_ sessionManager: GCKSessionManager, didSuspend session: GCKSession, with reason: GCKConnectionSuspendReason) {
            emitSuspended(session)
    }
    
    /// Called when a Cast session is suspended
    /// 
    /// This delegate method is invoked when a Cast session is temporarily suspended.
    /// This is the Cast-specific version of didSuspend for GCKSession.
    ///
    /// - Parameters:
    ///   - sessionManager: The session manager instance
    ///   - session: The Cast session that was suspended
    ///   - reason: The reason for the suspension
    public func sessionManager(_ sessionManager: GCKSessionManager, didSuspend session: GCKCastSession, with reason: GCKConnectionSuspendReason) {
            emitSuspended(session)
    }
    
    /// Called when a session is about to resume
    /// 
    /// This delegate method is invoked just before a suspended session resumes.
    /// Updates Flutter with the resuming session state.
    ///
    /// - Parameters:
    ///   - sessionManager: The session manager instance
    ///   - session: The session that will resume
    public func sessionManager(_ sessionManager: GCKSessionManager, willResumeSession session: GCKSession) {
        onSessionChanged(session)
    }
    
    /// Called when a session has resumed
    /// 
    /// This delegate method is invoked after a suspended session has resumed.
    /// Restarts media client listening and restores session state.
    ///
    /// - Parameters:
    ///   - sessionManager: The session manager instance
    ///   - session: The session that resumed
    public func sessionManager(_ sessionManager: GCKSessionManager, didResumeSession session: GCKSession) {
        onSessionChanged(session)
        RemoteMediaClienteMethodChannel.instance.startListen()
        RemoteMediaClienteMethodChannel.instance.resumeSession();
    }
    
    /// Called when a Cast session has resumed
    /// 
    /// This delegate method is invoked after a suspended Cast session has resumed.
    /// This is the Cast-specific version of didResumeSession for GCKSession.
    ///
    /// - Parameters:
    ///   - sessionManager: The session manager instance
    ///   - session: The Cast session that resumed
    public func sessionManager(_ sessionManager: GCKSessionManager, didResumeCastSession session: GCKCastSession) {
        onSessionChanged(session)
    }
    
    /// Called when a Cast session is about to resume
    /// 
    /// This delegate method is invoked just before a suspended Cast session resumes.
    /// This is the Cast-specific version of willResumeSession for GCKSession.
    ///
    /// - Parameters:
    ///   - sessionManager: The session manager instance
    ///   - session: The Cast session that will resume
    public func sessionManager(_ sessionManager: GCKSessionManager, willResumeCastSession session: GCKCastSession) {
        onSessionChanged(session)
    }
    
    /// Called when a device in the session is updated
    /// 
    /// This delegate method is invoked when the Cast device information changes
    /// during an active session (e.g., device name change).
    ///
    /// - Parameters:
    ///   - sessionManager: The session manager instance
    ///   - session: The session containing the updated device
    ///   - device: The updated device information
    public func sessionManager(_ sessionManager: GCKSessionManager, session: GCKSession, didUpdate device: GCKDevice) {
        // Data-only: device info changed, connection state didn't — skip
        // to avoid dedup oscillation between GCKSession/GCKCastSession states
    }
    
    /// Called when device volume changes
    /// 
    /// This delegate method is invoked when the Cast device's volume or mute
    /// state changes. Updates Flutter with the new session state.
    ///
    /// - Parameters:
    ///   - sessionManager: The session manager instance
    ///   - session: The session with volume changes
    ///   - volume: The new volume level (0.0 to 1.0)
    ///   - muted: Whether the device is muted
    public func sessionManager(_ sessionManager: GCKSessionManager, session: GCKSession, didReceiveDeviceVolume volume: Float, muted: Bool) {
        // Data-only: volume changed, connection state didn't — skip
        // to avoid dedup oscillation between GCKSession/GCKCastSession states
    }
    
    /// Called when Cast device volume changes
    /// 
    /// This delegate method is invoked when the Cast device's volume or mute
    /// state changes. This is the Cast-specific version for GCKCastSession.
    ///
    /// - Parameters:
    ///   - sessionManager: The session manager instance
    ///   - session: The Cast session with volume changes
    ///   - volume: The new volume level (0.0 to 1.0)
    ///   - muted: Whether the device is muted
    public func sessionManager(_ sessionManager: GCKSessionManager, castSession session: GCKCastSession, didReceiveDeviceVolume volume: Float, muted: Bool) {
        // Data-only: volume changed, connection state didn't — skip
        // to avoid dedup oscillation between GCKSession/GCKCastSession states
    }
    
    /// Called when device status changes
    /// 
    /// This delegate method is invoked when the Cast device reports a status
    /// text change (e.g., "Ready to cast", media title, etc.).
    ///
    /// - Parameters:
    ///   - sessionManager: The session manager instance
    ///   - session: The session with status changes
    ///   - statusText: The new status text from the device
    public func sessionManager(_ sessionManager: GCKSessionManager, session: GCKSession, didReceiveDeviceStatus statusText: String?) {
        // Data-only: device status text changed, connection state didn't — skip
        // to avoid dedup oscillation between GCKSession/GCKCastSession states
    }

    // MARK: - Helper Methods
    
    /// Forcefully resets a stuck session.
    ///
    /// 1. Early-returns when there is no current session — nothing to reset.
    /// 2. Removes the session manager listener so `endSessionAndStopCasting`
    ///    does not generate spurious `willEnd`/`didEnd` callbacks on the
    ///    Flutter side.
    /// 3. Cleans up the media client (listener, position timer, queue).
    /// 4. Force-ends the existing session via `endSessionAndStopCasting(true)`.
    /// 5. Resets the dedup state (`_lastEmittedConnectionState`) so the next
    ///    session is tracked from scratch.
    /// 6. Explicitly emits a `null` session to Flutter. `onSessionChanged(nil)`
    ///    is intentionally bypassed here because its dedup check (`nil == nil`)
    ///    would silently drop the emission.
    /// 7. Re-adds the session manager listener.
    ///
    /// - Parameter result: Flutter result callback
    private func resetSession(_ result: FlutterResult) {
        print("[GoogleCast] resetSession: force-ending session and cleaning up all state")

        // Nothing to reset — avoid unnecessary listener churn and media cleanup
        guard sessionManager.currentSession != nil else {
            result(true)
            return
        }

        // Remove listener so endSessionAndStopCasting does not fire
        // willEnd/didEnd and produce stale events on the Flutter side
        sessionManager.remove(self)

        // Clean up media client
        RemoteMediaClienteMethodChannel.instance.cleanUp()

        // Force-end the existing session
        sessionManager.endSessionAndStopCasting(true)

        // Reset dedup state — the next session will be tracked from scratch
        _lastEmittedConnectionState = nil

        // Explicitly notify Flutter that the session is gone. We bypass
        // onSessionChanged(nil) because its dedup check would silently skip
        // the emission when no previous null has been tracked.
        channel?.invokeMethod("onCurrentSessionChanged", arguments: nil)

        // Re-add listener
        sessionManager.add(self)

        result(true)
    }
    
    /// Emits a `disconnecting` state to Flutter for `willEnd` callbacks.
    ///
    /// iOS GCK SDK may set `session.connectionState` to `.disconnected`
    /// before firing `willEnd`, so reading the property directly would skip
    /// the `disconnecting` transition entirely. This method overrides the
    /// serialized `connectionState` in the dictionary to `.disconnecting`,
    /// ensuring the Dart side receives the proper state sequence:
    /// `connected` → `disconnecting` → `disconnected` → `nil`.
    ///
    /// - Parameter session: The session that is about to end
    /// A suspended session is parked, not ended: the receiver keeps playing
    /// and the SDK resumes the connection when the app returns. Dart gets it
    /// as `connectionState` 4 (`GoogleCastConnectState.suspended`).
    private func emitSuspended(_ session: GCKSession) {
        _lastEmittedConnectionState = nil
        var dict = session.toDict()
        dict["connectionState"] = 4
        channel?.invokeMethod("onCurrentSessionChanged", arguments: dict)
    }

    private func emitDisconnecting(_ session: GCKSession) {
        let disconnecting: GCKConnectionState = .disconnecting
        if disconnecting == _lastEmittedConnectionState { return }
        _lastEmittedConnectionState = disconnecting
        
        var dict = session.toDict()
        dict["connectionState"] = GCKConnectionState.disconnecting.rawValue
        channel?.invokeMethod("onCurrentSessionChanged", arguments: dict)
    }
    
    /// Notifies Flutter of session state changes
    /// 
    /// This helper method sends session updates to the Flutter side via
    /// the method channel. It converts the session object to a dictionary
    /// format suitable for Flutter consumption.
    /// 
    /// Deduplicates events: only emits when the connection state actually
    /// changes, preventing the flood of identical events from multiple
    /// GCKSessionManagerListener callbacks.
    ///
    /// - Parameter session: The session that changed, or nil if session ended
    private func onSessionChanged(_ session : GCKSession?){
        let currentState = session?.connectionState
        
        // Skip if the connection state hasn't changed
        if currentState == _lastEmittedConnectionState {
            return
        }
        _lastEmittedConnectionState = currentState
        
        channel?.invokeMethod("onCurrentSessionChanged", arguments: session?.toDict())
    }
    
}
