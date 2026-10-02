//
//  QueueItemsExtensions.swift
//  google_cast
//
//  Created by LUIZ FELIPE ALVES LIMA on 30/06/22.
//

import Foundation
import GoogleCast

extension GCKMediaQueueItem {
    static func fromMap(_ args : Dictionary<String, Any>) -> GCKMediaQueueItem? {
        
        let activeTrackIds = args["activeTrackIds"] as? [NSNumber]
        let autoplay = args["autoplay"] as? Bool ?? true
        guard let mediaDict = args["media"] as? Dictionary<String, Any>,
              let mediaInformation = GCKMediaInformation.fromMap(mediaDict) else {
            return nil
        }
        let startTime = (args["startTime"] as? NSNumber)?.doubleValue ?? 0
        let preloadTime = (args["preloadTime"] as? NSNumber)?.doubleValue ?? 0
        let customData = args["customData"] as? Dictionary<String,Any>
        let item = GCKMediaQueueItem(mediaInformation: mediaInformation, autoplay: autoplay, startTime: startTime, preloadTime: preloadTime, activeTrackIDs: activeTrackIds, customData: customData)
        
        
        return item
        
    }
    
    func toMap() -> Dictionary<String,Any> {
        var dict = Dictionary<String,Any>()
        dict["itemId"]  = self.itemID
        if !(self.preloadTime.isNaN || self.preloadTime.isInfinite) {
            dict["preloadTime"] =  Int(self.preloadTime)
        }
        if !(self.startTime.isNaN || self.startTime.isInfinite){
            dict["startTime"] = Int(self.startTime)
        }
        
        dict["mediaInformation"]  = self.mediaInformation.toMap()
        dict["autoPlay"] = self.autoplay
        dict["activeTracksIds"] = self.activeTrackIDs
        if !(self.playbackDuration.isNaN || self.playbackDuration.isInfinite){
            dict["playbackDuration"]  = Int(self.playbackDuration)
        }
        return dict
    }
}
