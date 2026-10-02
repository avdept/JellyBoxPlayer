//
//  MediaMetatadaExtensions.swift
//  google_cast
//
//  Created by LUIZ FELIPE ALVES LIMA on 28/06/22.
//

import Foundation
import GoogleCast



extension GCKMediaMetadata {
    /// Maps raw Dart keys to Google Cast canonical metadata keys. Standard
    /// fields sent under their JSON names would be stored as custom fields,
    /// which receivers never display. Unrecognised keys keep their own name
    /// so custom metadata still works.
    private static let canonicalKeys: [String: String] = [
        "title": kGCKMetadataKeyTitle,
        "subtitle": kGCKMetadataKeySubtitle,
        "artist": kGCKMetadataKeyArtist,
        "albumArtist": kGCKMetadataKeyAlbumArtist,
        "albumName": kGCKMetadataKeyAlbumTitle,
        "composer": kGCKMetadataKeyComposer,
        "studio": kGCKMetadataKeyStudio,
        "seriesTitle": kGCKMetadataKeySeriesTitle,
        "season": kGCKMetadataKeySeasonNumber,
        "episode": kGCKMetadataKeyEpisodeNumber,
        "trackNumber": kGCKMetadataKeyTrackNumber,
        "discNumber": kGCKMetadataKeyDiscNumber,
        "location": kGCKMetadataKeyLocationName,
        "latitude": kGCKMetadataKeyLocationLatitude,
        "longitude": kGCKMetadataKeyLocationLongitude,
        "width": kGCKMetadataKeyWidth,
        "height": kGCKMetadataKeyHeight,
    ]

    func toMap() -> Dictionary<String,Any?> {
        var dict = Dictionary<String,Any?>()
        dict["type"] = self.metadataType.rawValue
        dict["images"] =  (self.images() as! [GCKImage]).map{
            image in
            image.toMap()
            
        }
        let creationDate = self.date(forKey: kGCKMetadataKeyCreationDate)
        let releaseDate = self.date(forKey: kGCKMetadataKeyReleaseDate)
        let broadCastDate = self.date(forKey: kGCKMetadataKeyBroadcastDate)
        let title = self.string(forKey: kGCKMetadataKeyTitle)
        let subtitle = self.string(forKey: kGCKMetadataKeySubtitle)
        let artist = self.string(forKey: kGCKMetadataKeyArtist)
        let albumArtist = self.string(forKey: kGCKMetadataKeyAlbumArtist)
        let albumTitle = self.string(forKey: kGCKMetadataKeyAlbumTitle)
        let albumComposer = self.string(forKey: kGCKMetadataKeyComposer)
        let albumDiscNumber = self.integer(forKey: kGCKMetadataKeyDiscNumber)
        let albumTrackNumber = self.integer(forKey: kGCKMetadataKeyTrackNumber)
        let seasonNumber = self.integer(forKey: kGCKMetadataKeySeasonNumber)
        let episodeNumber = self.integer(forKey: kGCKMetadataKeyEpisodeNumber)
        let serieTitle = self.string(forKey: kGCKMetadataKeySeriesTitle)
        let studio = self.string(forKey: kGCKMetadataKeyStudio)
        let width = self.string(forKey: kGCKMetadataKeyWidth)
        let height = self.string(forKey: kGCKMetadataKeyHeight)
        let locationName = self.string(forKey: kGCKMetadataKeyLocationName)
        let locationLatitude = self.double(forKey: kGCKMetadataKeyLocationLatitude)
        let locationLongitude = self.double(forKey: kGCKMetadataKeyLocationLongitude)
        dict["creationDate"] = creationDate?.timeIntervalSince1970
        dict["releaseDate"] = releaseDate?.timeIntervalSince1970
        dict["broadcastDate"] = broadCastDate?.timeIntervalSince1970
        dict["title"] = title
        dict["subtitle"] = subtitle
        dict["artist"] = artist
        dict["albumArtist"] = albumArtist
        dict["albumTitle"] = albumTitle
        dict["composer"] = albumComposer
        dict["discNumber"] = albumDiscNumber
        dict["trackNumber"] = albumTrackNumber
        dict["seasonNumber"] = seasonNumber
        dict["episodeNumber"] = episodeNumber
        dict["serieTitle"] = serieTitle
        dict["studio"] = studio
        dict["width"] = width
        dict["height"] = height
        dict["locationName"] = locationName
        dict["locationLatitude"] = locationLatitude
        dict["locationLongitude"] = locationLongitude
        return dict
        
    }
    
    
    static func fromMap(_ imulatbleDict : Dictionary<String, Any >) ->  GCKMediaMetadata? {
        var mutableDict = imulatbleDict
       
        
       guard let metadataTypeValue = mutableDict["metadataType"] as? Int,
             let metadataType = GCKMediaMetadataType(rawValue: metadataTypeValue) else {
           return nil
           
       }
        mutableDict.removeValue(forKey: "metadataType")
        let metadata = GCKMediaMetadata(metadataType: metadataType)
        
        if let images = mutableDict["images"] as? [Dictionary<String, Any>] {
            for image in images {

            guard let url = URL(string: image["url"] as? String ?? "" ) else {
                    continue
                }    
                metadata.addImage(GCKImage(url: url, width: image["width"] as? Int ?? 0 , height: image["height"] as? Int ?? 0 ))
                
            }
        }
        
        mutableDict.removeValue(forKey: "images")
        
        
      
        for mapValue in mutableDict{
            let key = GCKMediaMetadata.canonicalKeys[mapValue.key] ?? mapValue.key
            switch mapValue.value {
            case let stringValue as String:
                metadata.setString(stringValue, forKey: key)
            case let intValue as Int:
                metadata.setInteger(intValue, forKey: key)
            case let doubleValue as Double:
                 metadata.setDouble(doubleValue, forKey: key)
            default:
                break
            }
            
            if let timeInterval = mapValue.value as? Double {
                let date = Date(timeIntervalSince1970: timeInterval / 1000)
                switch mapValue.key {
                case "broadcastDate":
                    metadata.setDate(date, forKey: kGCKMetadataKeyBroadcastDate)
                case "releaseDate":
                    metadata.setDate(date, forKey: kGCKMetadataKeyReleaseDate)
                case "creationDate", "creationDateTime":
                    metadata.setDate(date, forKey: kGCKMetadataKeyCreationDate)
                default:
                    break
                }
            }
            
        }

        
        return metadata
        
        
    }
}
