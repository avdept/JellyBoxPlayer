//
//  SeekOptionsExtensions.swift
//  google_cast
//
//  Created by LUIZ FELIPE ALVES LIMA on 27/06/22.
//

import Foundation
import GoogleCast

extension GCKMediaSeekOptions {
    static func fromMap(args : Dictionary<String, Any>) -> GCKMediaSeekOptions {
        let options = GCKMediaSeekOptions.init()
        if let position = args["position"] as? Int {
            options.interval = TimeInterval(position)
        } else if let position = args["position"] as? Double {
            options.interval = TimeInterval(position)
        }
        options.relative = args["relative"] as? Bool ?? false
        if let resumeStateValue = args["resumeState"] as? Int {
            options.resumeState = GCKMediaResumeState(rawValue: resumeStateValue) ?? .play
        } else {
            options.resumeState = .play
        }
        options.seekToInfinite = args["seekToInfinity"] as? Bool ?? false
        return options
    }
}
