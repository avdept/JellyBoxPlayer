//
//  CastDeviceExtensions.swift
//  google_cast
//
//  Created by LUIZ FELIPE ALVES LIMA on 24/06/22.
//

import Foundation
import GoogleCast

/// Extension for GCKDevice to provide Flutter-compatible data conversion
/// 
/// This extension adds functionality to convert Google Cast SDK device objects
/// into dictionary format suitable for transmission to Flutter. It ensures
/// all relevant device information is properly serialized and accessible
/// from the Flutter side.
///
/// The extension provides a standardized way to represent Cast device
/// information across the Flutter-iOS bridge, maintaining consistency
/// in device data representation.
///
/// - Author: LUIZ FELIPE ALVES LIMA
/// - Since: iOS 10.0+
extension GCKDevice{
    
    /// Converts the GCKDevice object to a Flutter-compatible dictionary
    /// 
    /// This method serializes all relevant Cast device properties into a
    /// dictionary format that can be transmitted to Flutter via method channels.
    /// The resulting dictionary contains all essential device information
    /// needed for device identification and display in the Flutter UI.
    ///
    /// Dictionary keys and their corresponding values:
    /// - `networkAddress`: Device IP address as String
    /// - `servicePort`: Cast service port number
    /// - `modelName`: Device model name (e.g., "Chromecast", "Google Nest Hub")
    /// - `statusText`: Current device status text
    /// - `isOnLocalNetwork`: Boolean indicating if device is on local network
    /// - `type`: Device type as raw integer value
    /// - `category`: Device category classification
    /// - `deviceID`: Unique device identifier
    /// - `deviceVersion`: Device firmware/software version
    /// - `friendlyName`: User-friendly device name for display
    /// - `uniqueID`: Unique identifier for the device instance
    ///
    /// - Returns: Dictionary containing all device properties for Flutter consumption
    /// - Note: This method ensures all properties are safely unwrapped and converted
    ///         to Flutter-compatible types
    func toDict() ->  Dictionary<String, Any> {
        var dict =  Dictionary<String, Any>()
        dict["networkAddress"] =    self.networkAddress.ipAddress
        dict["servicePort"] =    self.servicePort
        dict["modelName"] =   self.modelName
        dict["statusText"] =   self.statusText
        dict["isOnLocalNetwork"] =   self.isOnLocalNetwork
        dict["type"] =   self.type.rawValue
        dict["category"] =   self.category
        dict["deviceID"] =   self.deviceID
        dict["deviceVersion"] =   self.deviceVersion
        dict["friendlyName"] =   self.friendlyName
        dict["uniqueID"] = self.uniqueID
        
        return dict
    }
}