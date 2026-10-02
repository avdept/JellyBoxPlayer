//
//  MediaTrack.swift
//  google_cast
//
//  Created by LUIZ FELIPE ALVES LIMA on 29/06/22.
//

import Foundation
import GoogleCast

extension GCKMediaTrack {
    
    static func fromMap(_ args : Dictionary<String, Any> ) -> GCKMediaTrack? {
        
        let identifier = args["trackId"] as? Int ?? 0
        let contentIdentifier = args["trackContentId"] as? String
        let contentType = args["trackContentType"] as? String ?? ""
        var trackType :  GCKMediaTrackType
        if let trackTypeInt = args["type"] as? Int {
            trackType = GCKMediaTrackType.init(rawValue: trackTypeInt) ?? .unknown
        }else {
            trackType = .unknown
        }
        
        var trackSubtype: GCKMediaTextTrackSubtype
        if let trackSubtypeInt = args["subtype"] as? Int {
            trackSubtype = GCKMediaTextTrackSubtype.init(rawValue: trackSubtypeInt) ?? .unknown
        }else {
            trackSubtype = .unknown
        }
        
        let name = args["name"] as? String
        let language = args["language"] as? String

        // For text tracks (subtitles/captions), a missing or empty language code
        // prevents GCKMediaTrack from loading correctly on the receiver side.
        // Fall back to "und" (ISO 639-2 undetermined) so the track is always valid.
        let resolvedLanguage: String?
        if trackType == .text {
            let raw = language ?? ""
            resolvedLanguage = raw.isEmpty ? "und" : raw
        } else {
            resolvedLanguage = language
        }

        let mediaTrack = GCKMediaTrack.init(
            identifier: identifier,
            contentIdentifier: contentIdentifier,
            contentType: contentType,
            type: trackType,
            textSubtype: trackSubtype,
            name: name,
            languageCode: resolvedLanguage,
            customData: nil)

        return mediaTrack
    }
    
    func toMap() -> Dictionary<String, Any>{
        var dict  = Dictionary<String, Any>()
        dict["id"] = self.identifier
        dict["content_type"] = self.contentType
        dict["type"] = self.type.rawValue
        dict["language_code"] = self.languageCode
        dict["name"] = self.name
        dict["subtype"] = self.textSubtype.rawValue
        dict["content_id"] = self.contentIdentifier
        dict["custom_data"] = self.customData
        return dict
    }
}
