import Flutter
import UIKit
import GoogleCast

/// Main Google Cast plugin for iOS implementation
/// 
/// This class serves as the entry point for the Flutter Google Cast plugin on iOS.
/// It inherits from `GCKCastContext` to provide direct access to the Google Cast SDK
/// functionality and implements multiple protocols to handle Flutter communication
/// and Cast SDK events.
///
/// The plugin manages:
/// - Google Cast context initialization and configuration
/// - Registration of all method channels for different Cast features
/// - Logging and debugging of Cast SDK operations
/// - Integration with the iOS application lifecycle
///
/// - Note: This class follows the singleton pattern provided by the Google Cast SDK
/// - Author: LUIZ FELIPE ALVES LIMA
/// - Since: iOS 10.0+
@objc(GoogleCastPlugin)
public class SwiftGoogleCastPlugin: NSObject, GCKLoggerDelegate, FlutterPlugin, UIApplicationDelegate {
    static weak var instance: SwiftGoogleCastPlugin?
    
    // MARK: - Properties
    
    /// Debug logging flag for Google Cast SDK
    /// Set to `true` to enable verbose logging for debugging Cast operations
    let kDebugLoggingEnabled = false
    
    /// Whether to stop casting when the app is terminated
    /// This is set from Flutter via GoogleCastOptions.stopCastingOnAppTerminated
    private var stopCastingOnAppTerminated = false

    /// Tracks whether discovery should be restored when returning to foreground.
    /// This stays aligned with Flutter-driven start/stop requests and the
    /// discovery state observed before backgrounding.
    var shouldResumeDiscoveryOnForeground = false
    
    /// Flutter method channel for Cast context operations
    /// Handles communication between Flutter and native iOS for context-related methods
    private var channel : FlutterMethodChannel?

    // MARK: - Google Cast SDK Properties
    
    /// Access the shared Cast session manager
    /// - Returns: The global GCKSessionManager instance from the Cast context
    public var sessionManager: GCKSessionManager {
        GCKCastContext.sharedInstance().sessionManager
    }

    /// Access the shared Cast discovery manager
    /// - Returns: The global GCKDiscoveryManager instance from the Cast context
    public var discoveryManager: GCKDiscoveryManager {
        GCKCastContext.sharedInstance().discoveryManager
    }

    // MARK: - Flutter Plugin Registration
    
    /// Registers the plugin with Flutter and sets up all method channels
    /// 
    /// This method is called automatically by Flutter during plugin initialization.
    /// It creates an instance of the main plugin and registers all the specialized
    /// method channels for different Cast SDK features.
    ///
    /// Method channels registered:
    /// - `google_cast.context`: Main Cast context operations
    /// - `google_cast.session_manager`: Session management (via FGCSessionManagerMethodChannel)
    /// - `google_cast.session`: Individual session operations (via FGCSessionMethodChannel)
    /// - `google_cast.discovery_manager`: Device discovery (via FGCDiscoveryManagerMethodChannel)
    /// - `google_cast.remote_media_client`: Media control (via RemoteMediaClienteMethodChannel)
    ///
    /// - Parameter registrar: The Flutter plugin registrar for method channel setup
  public static func register(with registrar: FlutterPluginRegistrar) {
   
      let instance = SwiftGoogleCastPlugin()
      Self.instance = instance
      
      // Set up main Cast context method channel
      instance.channel = FlutterMethodChannel(name: "google_cast.context", binaryMessenger: registrar.messenger())
    
      registrar.addMethodCallDelegate(instance, channel: instance.channel!)
      
      // Register all specialized method channels for Cast features
      FGCSessionManagerMethodChannel.register(with: registrar)
      FGCSessionMethodChannel.register(with: registrar)
      FGCDiscoveryManagerMethodChannel.register(with: registrar)
      RemoteMediaClienteMethodChannel.register(with: registrar)
  }

    // MARK: - Flutter Method Call Handling
    
    /// Handles method calls from the Flutter side
    /// 
    /// This method processes incoming method calls from Flutter and routes them
    /// to the appropriate handler functions. Currently handles Cast context
    /// initialization and configuration.
    ///
    /// Supported methods:
    /// - `setSharedInstanceWithOptions`: Initializes the Google Cast context with provided options
    ///
    /// - Parameters:
    ///   - call: The Flutter method call containing method name and arguments
    ///   - result: Callback to return results or errors to Flutter
  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {

      switch call.method {
      case "setSharedInstanceWithOptions":
          setSharedInstanceWithOption(arguments: call.arguments as! Dictionary<String, Any>, result: result)
          break
      default:
          result(FlutterMethodNotImplemented)
          break
      }
  }
    // MARK: - Google Cast Context Management
    
    /// Initializes the Google Cast context with provided options
    /// 
    /// This method sets up the Google Cast SDK with the configuration options
    /// provided from Flutter. It handles:
    /// - Creating Cast options from the provided arguments
    /// - Initializing the shared Cast context instance
    /// - Setting up debug logging if enabled
    /// - Registering listeners for discovery and session events
    /// - Starting device discovery automatically
    ///
    /// - Parameters:
    ///   - arguments: Dictionary containing Cast configuration options from Flutter
    ///   - result: Flutter result callback (currently unused)
    /// - Note: This method should be called once during app initialization
    private func setSharedInstanceWithOption(arguments: Dictionary<String, Any> ,result: @escaping FlutterResult){
      
            // Parse Cast options from Flutter arguments
        let option =  GCKCastOptions.fromMap(arguments)
        
        // Store the stopCastingOnAppTerminated option
        if let stopOnTerminated = arguments["stopCastingOnAppTerminated"] as? Bool {
            stopCastingOnAppTerminated = stopOnTerminated
            if kDebugLoggingEnabled {
                print("stopCastingOnAppTerminated set to: \(stopOnTerminated)")
            }
        }
        
        // Initialize the shared Cast context with parsed options
       GCKCastContext.setSharedInstanceWith(option)
        
        // Enable console logging for debugging
        GCKLogger.sharedInstance().consoleLoggingEnabled = kDebugLoggingEnabled
        GCKLogger.sharedInstance().delegate = self

        let filter = GCKLoggerFilter.init()
        filter.minimumLevel = kDebugLoggingEnabled ? GCKLoggerLevel.verbose : GCKLoggerLevel.warning
        GCKLogger.sharedInstance().filter = filter
        
        // Register listeners for Cast events
        discoveryManager.add(FGCDiscoveryManagerMethodChannel.instance)   
        sessionManager.add(FGCSessionManagerMethodChannel.instance )

        // Start discovering Cast devices automatically
        // Return to Flutter immediately before starting potentially expensive operations
        // so the Dart side gets fast feedback.
        result(true)

        if !option.disableDiscoveryAutostart {
            shouldResumeDiscoveryOnForeground = true
            discoveryManager.startDiscovery()
        }

        if kDebugLoggingEnabled {
            print("Cast context initialized")
        }

        // Observe application lifecycle to stop discovery and remove listeners when app closes
        addLifecycleObserversIfNeeded()
    }

    // MARK: - Teardown / Lifecycle handlers

    /// Cleanly stops discovery and removes registered listeners to avoid callbacks after deallocation.
    private func tearDown() {
        // Stop discovery if it's running
        if kDebugLoggingEnabled {
            print("SwiftGoogleCastPlugin: tearing down - stopping discovery and removing listeners")
        }
        discoveryManager.stopDiscovery()

        // Remove any previously registered listeners (safe to call even if not registered)
        discoveryManager.remove(FGCDiscoveryManagerMethodChannel.instance)
        sessionManager.remove(FGCSessionManagerMethodChannel.instance)

        // Remove logger delegate
        GCKLogger.sharedInstance().delegate = nil
    }

    @objc private func applicationWillTerminateNotification(_ notification: Notification) {
        // End the cast session and stop casting when app is terminated (if option is enabled)
        // This ensures the receiver stops casting when the app is killed
        if stopCastingOnAppTerminated && sessionManager.hasConnectedSession() {
            if kDebugLoggingEnabled {
                print("SwiftGoogleCastPlugin: App terminating - ending cast session and stopping casting (stopCastingOnAppTerminated=true)")
            }
            sessionManager.endSessionAndStopCasting(true)
        }
        tearDown()
    }

    @objc private func applicationDidEnterBackgroundNotification(_ notification: Notification) {
        // Switch to passive scan when app goes to background to save resources
        // but keep discovery alive so we don't lose state
        shouldResumeDiscoveryOnForeground = discoveryManager.discoveryState == .running && !discoveryManager.passiveScan
        discoveryManager.passiveScan = true
    }

    @objc private func applicationWillEnterForegroundNotification(_ notification: Notification) {
        // Restart active discovery when app returns to foreground
        discoveryManager.passiveScan = false
        if shouldResumeDiscoveryOnForeground && discoveryManager.discoveryState == .stopped {
            discoveryManager.startDiscovery()
        }
    }

    deinit {
        if Self.instance === self {
            Self.instance = nil
        }
        removeLifecycleObserversIfNeeded()
        tearDown()
    }

    // MARK: - Lifecycle observer helpers

    private var lifecycleObserversAdded = false

    private func addLifecycleObserversIfNeeded() {
        guard !lifecycleObserversAdded else { return }
        lifecycleObserversAdded = true

        if kDebugLoggingEnabled {
            print("SwiftGoogleCastPlugin: adding lifecycle observers")
        }

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationWillTerminateNotification(_:)),
                                               name: UIApplication.willTerminateNotification,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationDidEnterBackgroundNotification(_:)),
                                               name: UIApplication.didEnterBackgroundNotification,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationWillEnterForegroundNotification(_:)),
                                               name: UIApplication.willEnterForegroundNotification,
                                               object: nil)
    }

    private func removeLifecycleObserversIfNeeded() {
        guard lifecycleObserversAdded else { return }
        lifecycleObserversAdded = false
        NotificationCenter.default.removeObserver(self, name: UIApplication.willTerminateNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    // MARK: - Google Cast Logging Delegate
    
    /// Handles log messages from the Google Cast SDK
    /// 
    /// This delegate method is called by the Cast SDK to report log messages
    /// at various levels (verbose, debug, info, warning, error). Currently
    /// prints all messages to the console for debugging purposes.
    ///
    /// - Parameters:
    ///   - message: The log message content
    ///   - level: The severity level of the log message
    ///   - function: The function name where the log originated
    ///   - location: The file and line number information
    public func logMessage(_ message: String,
                      at level: GCKLoggerLevel,
                      fromFunction function: String,
                      location: String) {
          // Print formatted log message with function name for easier debugging
          if kDebugLoggingEnabled {
              print(function + " - " + message)
          }
    }
    
  

    
    
}
