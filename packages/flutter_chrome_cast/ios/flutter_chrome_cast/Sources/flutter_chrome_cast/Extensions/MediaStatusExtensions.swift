//
//  MediaStatusExtensions.swift
//  google_cast
//
//  Created by LUIZ FELIPE ALVES LIMA on 28/06/22.
//

import Foundation
import GoogleCast

extension GCKMediaStatus {
    
    func toMap() -> Dictionary<String, Any> {
    
        var dict = Dictionary<String, Any>()
        dict["mediaSessionID"] = self.mediaSessionID
        dict["playerState"] = self.playerState.rawValue
        dict["playingAd"] = self.playingAd
        dict["idleReason"] = self.idleReason.rawValue
        dict["playbackRate"] = self.playbackRate
        dict["mediaInformation"] = self.mediaInformation?.toMap()
        dict["repeatMode"] = self.queueRepeatMode.rawValue
        dict["activeTrackIds"] = self.activeTrackIDs
        dict["queueHasNextItem"] = self.queueHasNextItem
        dict["queueHasPreviousItem"] =  self.queueHasPreviousItem
        dict["currentItemId"] = self.currentItemID
        dict["volume"] = self.volume
        dict["isMuted"] = self.isMuted

        // Live seekable range
        if let liveSeekableRange = self.liveSeekableRange {
            dict["liveSeekableRange"] = [
                "start": Int(liveSeekableRange.startTime),
                "end": Int(liveSeekableRange.endTime),
                "isMovingWindow": liveSeekableRange.isMovingWindow,
                "isLiveDone": liveSeekableRange.isLiveDone
            ]
        }

        // Add stream position if available, though it's usually retrieved separately
        // dict["streamPosition"] = self.streamPosition

        return dict
    }
    
    
    
}
