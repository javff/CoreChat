//
//  FirebaseDataBaseServices.swift
//  SOSChatServices
//
//  Created by Juan  Vasquez on 11/13/18.
//  Copyright © 2018 javff. All rights reserved.
//

import Foundation
import Firebase

open class FirebaseDatabaseServices{
    
    public class func initFirebase(){
        
        let filePath = Bundle.main.path(forResource: "GoogleService-Info",
                                        ofType: "plist")!
        let options = FirebaseOptions(contentsOfFile: filePath)
        FirebaseApp.configure(options: options!)
        Database.database().isPersistenceEnabled = true
        
    }
}
