//
//  ChatManager.swift
//  SOSChatServices
//
//  Created by Juan  Vasquez on 11/13/18.
//  Copyright © 2018 javff. All rights reserved.
//

import Foundation
import ObjectMapper
import FirebaseDatabase
import FirebaseStorage


open class ChatManager: ChatManagerProtocol{
    
    public var storage: StorageManagerProtocol
    public var channel: ChannelModelProtocol
    private let myUid:String
    private let settings:CoreChatSettings
    
    //MARK: - define firebase vars
    
    private lazy var firebaseDataBasePointer = self.settings.firebaseDataBase
    
    private lazy var messageRef: DatabaseReference = Database.database(url: firebaseDataBasePointer).reference().child("messages/issues/\(channel.key ?? "")/messages")

    private lazy var channelIssuesRef: DatabaseReference = Database.database(url: firebaseDataBasePointer).reference().child("personal/\(myUid)/issues/\(channel.key ?? "")")
    
    private lazy var participantIssuesRef: DatabaseReference = Database.database(url: firebaseDataBasePointer).reference().child("personal/\(channel.participantId)/issues/\(channel.key ?? "")")

    public init(userUid: String,
                channel: ChannelModelProtocol,
                chatSettings:CoreChatSettings){
        
        self.storage = StorageManager(bucketSettings: chatSettings)
        self.settings = chatSettings
        self.myUid = userUid
        self.channel = channel
    }
    
    deinit {
        self.messageRef.removeAllObservers()
    }

    
    //MARK: - Observers funcs
    public func observerMessages(completion: @escaping(ChatModelProtocol) ->Void){
        
        let messageQuery = messageRef.queryLimited(toLast: 25)
        
        messageQuery.observe(.childAdded, with: { (snapshot) -> Void in
            
            guard let messageJSON = snapshot.value as? [String:Any], let
                message = Mapper<ChatMessageModel>().map(JSON: messageJSON) else{
                    return
            }
            
            message.key = snapshot.key
            completion(message)
    
        })
    }
    
    public func observerLastUpdateMessage(completion:@escaping(ChatModelProtocol) -> Void){
        
        self.messageRef.observe(.childChanged) { (snapshot) in
           
            guard let messageJSON = snapshot.value as? [String:Any], let
                message = Mapper<ChatMessageModel>().map(JSON: messageJSON) else{
                    return
            }
            
            message.key = snapshot.key
            completion(message)
        }
    }
    
    //MARK: - CREATE funcs
    @discardableResult
    public func createMessage(message:ChatModelProtocol) -> String?{
        
        let itemRef = self.messageRef.childByAutoId()
        message.uid = itemRef.key ?? message.uid
        itemRef.setValue(message.toJSON())
        
        let payload: [String:Any] = [
            "lastMessage": message.toJSON(),
            "lastUpdateTimestamp": message.timestamp
        ]
        
        
//        // update unreadMessageCount //
//
        let unreadMessageCountRef = self.participantIssuesRef.child("unreadMessageCount")
        
        unreadMessageCountRef.keepSynced(true)

        unreadMessageCountRef.observeSingleEvent(of: .value) { (snapshot, key) in

            let badgeCount = snapshot.value as? Int ?? 0
            let value = badgeCount + 1
            unreadMessageCountRef.setValue(value)
        }
       
        channelIssuesRef.updateChildValues(payload)
        participantIssuesRef.updateChildValues(payload)
        return itemRef.key
    }
    
    //MARK: - UPDATE funcs
    
    public func updateMessage(payload:[String:Any],messageKey: String){
        let itemRef = messageRef.child(messageKey)
        itemRef.updateChildValues(payload)
    }
    
    
    public func markMessageHowReaded(messageKey:String){
        let updatePayload:[String:Any] = [
            "statusReaded":true,
            "readedTimestamp": Int(Date().timeIntervalSince1970 * 1000)
        ]
        
        self.messageRef.child(messageKey).updateChildValues(updatePayload)
    }
    
    public func markMessageAsReceived(messageKey:String) {
        let updatePayload:[String:Any] = [
            "receivedTimestamp": Int(Date().timeIntervalSince1970 * 1000)
        ]
        
        self.messageRef.child(messageKey).updateChildValues(updatePayload)
    }
    
}
