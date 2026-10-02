//
//  MediaInfoExtensions.swift
//  google_cast
//
//  Created by LUIZ FELIPE ALVES LIMA on 27/06/22.
//

import Foundation
import GoogleCast

extension GCKMediaInformation{
    static func fromMap(_ arguments: Dictionary<String, Any> ) -> GCKMediaInformation? {
        let streamType: GCKMediaStreamType = {
                    switch arguments["streamType"] as? String {
                    case "BUFFERED":
                        return .buffered
                    case "LIVE":
                        return .live
                    case "NONE":
                        return .none
                    default:
                        return .unknown
                    }
                }()
        guard let contentUrlString = arguments["contentURL"] as? String,
              let contentUrl = URL(string: contentUrlString) else { return nil}
        
        let builder =  GCKMediaInformationBuilder.init(contentURL: contentUrl)
        builder.streamType = streamType
        if let contentID = arguments["contentID"] as? String, !contentID.isEmpty {
            builder.contentID = contentID
        }
        if let contentType = arguments["contentType"] as? String {
             builder.contentType = contentType
        }
        if let duration = arguments["duration"] as? TimeInterval {
            builder.streamDuration = duration
        } else if let duration = arguments["duration"] as? NSNumber {
            builder.streamDuration = duration.doubleValue
        }
        if let startAbsoluteTime = arguments["startAbsoluteTime"] as? Double {
            builder.startAbsoluteTime = startAbsoluteTime / 1000.0
        }
        
        if let hlsSegmentFormat = arguments["hlsSegmentFormat"] as? String {
             switch hlsSegmentFormat {
             case "aac":
                 builder.hlsSegmentFormat = .AAC
             case "ac3":
                 builder.hlsSegmentFormat = .AC3
             case "mp3":
                 builder.hlsSegmentFormat = .MP3
             case "ts":
                 builder.hlsSegmentFormat = .TS
             case "tsAac":
                 builder.hlsSegmentFormat = .TS_AAC
             default:
                 break
             }
         }
         
         if let hlsVideoSegmentFormat = arguments["hlsVideoSegmentFormat"] as? String {
             switch hlsVideoSegmentFormat {
             case "mpeg2Ts":
                 builder.hlsVideoSegmentFormat = .MPEG2_TS
             case "fmp4":
                 builder.hlsVideoSegmentFormat = .FMP4
             default:
                 break
             }
         }
        
        builder.customData = arguments["customData"]
        
        if let tracksDict = arguments["tracks"] as? [Dictionary<String, Any>] {
            builder.mediaTracks = tracksDict.compactMap{
                dict in
                GCKMediaTrack.fromMap(dict)
            }
        }
      
        if let metadataDict = arguments["metadata"] as? Dictionary<String, Any> {
            builder.metadata = GCKMediaMetadata.fromMap(metadataDict)
        }
        
        let buildedMediaInfo = builder.build()
        
        return buildedMediaInfo
    
    }
    
    func toMap() -> Dictionary<String, Any> {
        var dict = Dictionary<String, Any>()
        // Only return the receiver-reported contentID here. The plugin layer
        // (RemoteMediaClienteMethodChannel) is responsible for substituting
        // the contentID that the Flutter side originally passed when loading
        // media, because the Default Media Receiver does not always echo it
        // back in the first media status update. A contentURL fallback is
        // applied by the plugin layer only when no contentID is available at
        // all. This keeps iOS behaviour consistent with Android, where the
        // originally provided contentID is always delivered first.
        if let contentID = self.contentID, !contentID.isEmpty {
            dict["contentID"] = contentID
        }
        dict["contentType"] = self.contentType
        dict["streamType"] = self.streamType.rawValue
        dict["contentURL"] = self.contentURL?.absoluteString
        if self.streamDuration.isInfinite || self.streamDuration.isNaN {
             dict["duration"] = 0.0
        } else {
             dict["duration"] = self.streamDuration
        }
        dict["metadata"] = self.metadata?.toMap()
        dict["customData"] = self.customData

        if(self.mediaTracks != nil){
            dict["tracks"] = self.mediaTracks!.map{
                track in
                track.toMap()
                
            }
        }

        return dict
    }
    
}
