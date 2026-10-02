//
//  CastOptionsExtensions.swift
//  google_cast
//
//  Created by LUIZ FELIPE ALVES LIMA on 24/06/22.
//

import Foundation
import GoogleCast

/// Extension for GCKCastOptions to provide Flutter-to-iOS configuration conversion
/// 
/// This extension adds functionality to create Google Cast SDK configuration objects
/// from Flutter-provided dictionary data. It handles the conversion of Cast options
/// sent from Flutter into native iOS Cast SDK configuration objects.
///
/// The extension supports multiple Cast discovery criteria initialization methods
/// and various Cast configuration options, ensuring proper setup of the Cast SDK
/// based on Flutter application requirements.
///
/// - Author: LUIZ FELIPE ALVES LIMA
/// - Since: iOS 10.0+
extension  GCKCastOptions{
    
    /// Creates a GCKCastOptions object from a Flutter-provided dictionary
    /// 
    /// This static method parses a dictionary containing Cast configuration options
    /// from Flutter and creates the corresponding native GCKCastOptions object.
    /// It handles discovery criteria setup and various Cast SDK configuration
    /// parameters.
    ///
    /// Supported discovery criteria initialization methods:
    /// - `initWithApplicationID`: Initialize with a specific Cast app ID
    /// - `initWithNamespaces`: Initialize with custom message namespaces
    ///
    /// Supported configuration options:
    /// - `physicalVolumeButtonsWillControlDeviceVolume`: Whether hardware volume buttons control Cast device
    /// - `discoveryCriteria`: Configuration for Cast device discovery
    ///
    /// Dictionary structure expected:
    /// ```
    /// {
    ///   "discoveryCriteria": {
    ///     "method": "initWithApplicationID",
    ///     "applicationID": "your_cast_app_id"
    ///   },
    ///   "physicalVolumeButtonsWillControlDeviceVolume": true
    /// }
    /// ```
    ///
    /// - Parameter map: Dictionary containing Cast configuration options from Flutter
    /// - Returns: Configured GCKCastOptions object ready for Cast SDK initialization
    /// - Note: This method assumes required fields are present and properly typed
    static func fromMap(_ map : [String : Any]) ->  GCKCastOptions {
        
        // Parse discovery criteria configuration
        let discoveryCriteriaData : [String : Any] = map["discoveryCriteria"] as! [String : Any]
        var discoveryCriteria: GCKDiscoveryCriteria?
        let discoveryCriteriaInitializeMethod = discoveryCriteriaData["method"] as! String
        
        // Initialize discovery criteria based on method specified
        switch discoveryCriteriaInitializeMethod {
        case "initWithApplicationID":
            // Initialize with Cast application ID (most common case)
            discoveryCriteria = GCKDiscoveryCriteria.init(applicationID: discoveryCriteriaData["applicationID"] as! String)
            break;
            
        case "initWithNamespaces":
            // Initialize with custom message namespaces (advanced use case)
            discoveryCriteria = GCKDiscoveryCriteria.init(namespaces: discoveryCriteriaData["namespaces"] as! Set<String> )
            break
            
        default:
            // Default case - should not occur with proper Flutter implementation
            break
        }
        
        // Create Cast options with discovery criteria
        let option =  GCKCastOptions.init(discoveryCriteria: discoveryCriteria!)
        
        // Configure additional options if provided
        if let physicalVolumeButtonsWillControlDeviceVolume = map["physicalVolumeButtonsWillControlDeviceVolume"] as? Bool {
            // Set whether hardware volume buttons control Cast device volume
            option.physicalVolumeButtonsWillControlDeviceVolume = physicalVolumeButtonsWillControlDeviceVolume
        }

        if let suspendSessionsWhenBackgrounded = map["suspendSessionsWhenBackgrounded"] as? Bool {
            option.suspendSessionsWhenBackgrounded = suspendSessionsWhenBackgrounded
        }

        if let disableDiscoveryAutostart = map["disableDiscoveryAutostart"] as? Bool {
            option.disableDiscoveryAutostart = disableDiscoveryAutostart
        }

        if let disableAnalyticsLogging = map["disableAnalyticsLogging"] as? Bool {
            option.disableAnalyticsLogging = disableAnalyticsLogging
        }

        if let stopReceiverApplicationWhenEndingSession = map["stopReceiverApplicationWhenEndingSession"] as? Bool {
            option.stopReceiverApplicationWhenEndingSession = stopReceiverApplicationWhenEndingSession
        }

        if let startDiscoveryAfterFirstTapOnCastButton = map["startDiscoveryAfterFirstTapOnCastButton"] as? Bool {
            option.startDiscoveryAfterFirstTapOnCastButton = startDiscoveryAfterFirstTapOnCastButton
        }

        return option
    }
    
    
    
    
    
}
