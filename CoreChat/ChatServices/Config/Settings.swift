//
//  Settings.swift
//  ChatServices
//
//  Created by Juan  Vasquez on 1/4/19.
//  Copyright © 2019 Educate. All rights reserved.
//

import Foundation

public class FirebaseCoreChatSettings: CoreChatSettings{
    
    public var firebaseDataBase: String
    public var firebaseBucket: String
    
    public init(firebaseDataBase:String,firebaseBucket:String){
        self.firebaseDataBase = firebaseDataBase
        self.firebaseBucket = firebaseBucket
    }    
}
