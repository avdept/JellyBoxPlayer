//
//  SessionExtensions.swift
//  google_cast
//
//  Created by LUIZ FELIPE ALVES LIMA on 27/06/22.
//

import Foundation
import GoogleCast

 extension GCKSession {
     
     
     func toDict() -> Dictionary<String, Any> {
         
         var dict = [String : Any]()
         
          dict["device"] = self.device.toDict()
         dict["sessionID"] = self.sessionID
         dict["connectionState"] = self.connectionState.rawValue
         dict["currentDeviceMuted"] = self.currentDeviceMuted
         dict["currentDeviceVolume"] = self.currentDeviceVolume
         dict["deviceStatusText"] = self.deviceStatusText
        
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         return dict
         
         
     }
    
}
