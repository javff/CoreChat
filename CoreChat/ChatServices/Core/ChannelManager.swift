//
//  ChannelManager.swift
//  SOSChatServices
//
//  Created by Juan  Vasquez on 11/12/18.
//  Copyright © 2018 javff. All rights reserved.
//

import Foundation
import ObjectMapper
import FirebaseDatabase
import MessageKit
import AVFoundation
import Firebase



open class ChannelManager: NSObject, ChannelManagerProtocol{
    
    //MARK: - mandatory vars 
    public var myUid:String
    public var type: ChannelType
    public var coreSettings: CoreChatSettings
    private let firebaseDataBasePointer: String
    
    //MARK: - define firebase vars
    
    private var personalIssuesRef: DatabaseReference
    private var personalRef:DatabaseReference
    private let settings:CoreChatSettings

    //MARK: - Inits
    
    public init(userUid: String,
                type: ChannelType,
                channelSettings:CoreChatSettings){
        
        self.type = type
        self.myUid = userUid
        self.settings = channelSettings
        self.coreSettings = channelSettings
                
        self.firebaseDataBasePointer = settings.firebaseDataBase
        
        self.personalIssuesRef = Database.database(url: firebaseDataBasePointer).reference().child("personal/\(myUid)/issues")
        
        self.personalRef = Database.database(url: firebaseDataBasePointer).reference().child("personal/")
        
    }


    //MARK: - Define funcs
    
    /*** this function return a channel ref id */
    
    @discardableResult public func createRoom(channelPayload:ChannelModelProtocol) -> ChannelModelProtocol{
        
        let channelRef = self.personalIssuesRef.childByAutoId()
        channelRef.setValue(channelPayload.toJSON())
        channelPayload.key = channelRef.key
        
        let safeKey = channelRef.key ?? UUID.init().uuidString
        
        let currentPlanner = self.personalRef
                                  .child(channelPayload.participantId)
                                   .child("issues")
                                   .child(safeKey)
        
        
        var payload = channelPayload.toJSON()
        payload["participantId"] = myUid
        currentPlanner.setValue(payload)
        
        return channelPayload
    }
    
    public func registerPushToken(token: String) {
        
        let tokenPayload:[String:Any] = [
            "pushToken": token
        ]
        
        self.personalRef.child("\(myUid)").updateChildValues(tokenPayload)
    }
    
    public func changeUser(newUserId: String) {
        
        self.personalRef.removeAllObservers()
        self.personalIssuesRef.removeAllObservers()
        
        self.myUid = newUserId
    
        self.personalIssuesRef = Database.database(url: firebaseDataBasePointer)
                                        .reference()
                                        .child("personal/\(myUid)/issues")
        
        self.personalRef = Database.database(url: firebaseDataBasePointer)
                                    .reference()
                                    .child("personal/")
    }
    

    public func observerChangesInChannels(completion:@escaping(ChannelModelProtocol) ->Void){
        
        self.personalIssuesRef.observe(.childChanged) { (snapshot) in
            
            guard let channelJSON = snapshot.value as? [String:Any], let
                channel = Mapper<ChannelModel>().map(JSON: channelJSON) else{
                    return
            }
            
            channel.key = snapshot.key
            completion(channel)
            
        }
    }
    
    public func channelCollectionIsEmpty(completion:@escaping(Bool) -> Void){
        
        self.personalIssuesRef.observe(.value) { (snapshot) in
            
            completion(snapshot.value == nil)
        }
    }
    
    public func observerNewChannels(completion:@escaping(ChannelModelProtocol) ->Void){
        
        self.personalIssuesRef.queryOrdered(byChild: "lastUpdateTimestamp").observe(.childAdded) { (snapshot) in
            
            guard let channelJSON = snapshot.value as? [String:Any], let
                channel = Mapper<ChannelModel>().map(JSON: channelJSON) else{
                    return
            }
            
            channel.key = snapshot.key
            completion(channel)
        }
    }
    
    public func observerStatusChannel(completion: @escaping(_ closeChannel: Bool) -> Void){
        
        personalIssuesRef.observe(.childChanged) { (snapshot) in
            
            if  let status = snapshot.value as? Bool{
                completion(status)
            }
        }
    }
    
    public func updateAvatar(filePath:String){
        
        let payload = [
            "avatar":filePath
        ]
        
        let peronal = Database.database(url: firebaseDataBasePointer).reference().child("personal/\(myUid)/")
        
        peronal.updateChildValues(payload)
    }
    
    public func getAvatar(avatarId:String,completion:@escaping(_ url: URL?) -> Void){
        
        let personal = Database.database(url: firebaseDataBasePointer).reference().child("personal/\(avatarId)/avatar")
        
        personal.observeSingleEvent(of: .value) { (snapshot) in
            
            guard let urlString = snapshot.value as? String else{
                completion(nil)
                return
            }
            
            completion(URL(string: urlString))
        }
    }
    
    public func markAllMessagesReaded(channel: ChannelModelProtocol) {
        
        guard let key = channel.key else{
            return
        }
        
        let countRef = self.personalIssuesRef.child(key).child("unreadMessageCount")
        countRef.setValue(0)
        
    }
    
    public func setRoomRating(keyIssue: String, rateStars: Int, rateComments: String) {
        
//        let refPersonalRateStars = channelRef.child(keyIssue).child("rateStars")
//        let refPersonalRateComments = channelRef.child(keyIssue).child("rateComments")
//
//        let refPreviewRateStars = previewRef.child(keyIssue).child("rateStars")
//        let refPreviewRateComments = previewRef.child(keyIssue).child("rateComments")
        
        let updatePayload:[String:Any] = [
            "rateStars": rateStars,
            "rateComments": rateComments
        ]
        
        personalIssuesRef.child(keyIssue).updateChildValues(updatePayload)
//        previewRef.child(keyIssue).updateChildValues(updatePayload)
    }

}
