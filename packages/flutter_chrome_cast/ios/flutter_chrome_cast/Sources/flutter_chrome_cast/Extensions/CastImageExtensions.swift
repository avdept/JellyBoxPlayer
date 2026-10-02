//
//  CastImageExtensions.swift
//  google_cast
//
//  Created by LUIZ FELIPE ALVES LIMA on 28/06/22.
//

import Foundation
import GoogleCast


extension GCKImage {
    func toMap() -> Dictionary<String, Any?> {

        var dict = Dictionary<String, Any?>()
        dict["height"] =  self.height
        dict["width"] = self.width
        dict["url"] =  self.url.absoluteString
        return dict
    }
    
}
