//
//  QueuLoadOptions.swift
//  google_cast
//
//  Created by LUIZ FELIPE ALVES LIMA on 30/06/22.
//

import Foundation
import GoogleCast

extension GCKMediaQueueLoadOptions {
    static func fromMap(_ args: [String: Any]?) -> GCKMediaQueueLoadOptions? {
        guard args != nil else {
            return nil
        }

        let startIndex = args!["startIndex"] as? UInt ?? 0
        let playPosition = (args!["playPosition"] as? NSNumber)?.doubleValue ?? 0
        let repeatModeString = args!["repeatMode"] as? String ?? "OFF"
        let repeatMode: GCKMediaRepeatMode = {
            switch repeatModeString {
            case "OFF":
                return .off
            case "ALL":
                return .all
            case "SINGLE":
                return .single
            case "ALL_AND_SHUFFLE":
                return .allAndShuffle
            default:
                return .off
            }
        }()
        let customData = args!["customData"] as? [String: Any]

        let options = GCKMediaQueueLoadOptions.init()
        options.startIndex = startIndex
        options.playPosition = playPosition
        options.repeatMode = repeatMode
        options.customData = customData

        return options

    }
}
