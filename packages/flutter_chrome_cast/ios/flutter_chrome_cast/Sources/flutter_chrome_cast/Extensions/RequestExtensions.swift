//
//  RequestExtensions.swift
//  google_cast
//
//  Created by LUIZ FELIPE ALVES LIMA on 27/06/22.
//

import Foundation
import GoogleCast

extension GCKRequest  {
    
    func toMap() -> Dictionary<String, Any>{
        var dic = Dictionary<String,Any>()
        
        dic["inProgress"] = self.inProgress
        dic["isExternal"] = self.external
        dic["requestID"] = self.requestID
        if(self.error !=  nil){
            dic["error"] = String(describing: self.error)
        }
       
       
        

         return dic
        
        
    }
    
    
}
