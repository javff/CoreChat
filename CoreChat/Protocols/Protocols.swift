//
//  Protocols.swift
//  CoreChat
//
//  Created by Juan  Vasquez on 2/11/19.
//  Copyright © 2019 com.anincubator. All rights reserved.
//

import Foundation
import MessageKit


//MARK: - Enum Types

public enum ChannelType{
    case client
    case planner
}

public protocol ChatModelProtocol:class{
    
    var key:String {get set}
    var timestamp:Int {get set}
    var uid:String {get set}
    var iosID:String? {get set}
    var type: ChatMessageType? {get set}
    var link:String {get set}
    var message:String {get set}
    var rol:String {get set}
    var userId:String {get set}
    var date:Date? {get set}
    var localResource:URL? {get set}
    var mimeType:String? {get set}
    var statusReaded:Bool {get set}
    var readedTimestamp:TimeInterval {get set}
    var receivedTimestamp:TimeInterval {get set}
    var operationFailed:Bool {get set}
    var taskProgress:Progress? {get set}
    
    func toJSON() -> [String:Any]
    
    func isNotYetForDisplay() ->Bool
    
    func isDownloadType() -> Bool
    
    func isUploadType() -> Bool
    
    func  downloadMultimedia(progressHandler:@escaping(_ progress: Progress) ->Void,
                             completion: @escaping (_ localURL: URL?) -> Void)
    
}

public protocol ChannelModelProtocol: class{
    
    var key:String? {get set}
    var channelName:String {get set}
    var lastMessage:ChatModelProtocol? { get set }
    var lastUpdateTimestamp:TimeInterval { get set }
    var participantId: String {get set}
    var unreadMessageCount:Int {get set}
    
    func toJSON() -> [String:Any]
    
    init(channelName:String,
         lastUpdateTimestamp: TimeInterval,
         participantId:String)

}


public protocol ChatManagerProtocol:class{
    
    var storage: StorageManagerProtocol {get}
    
    var channel: ChannelModelProtocol {get}
    
    func observerMessages(completion: @escaping(ChatModelProtocol) ->Void)
    
    func observerLastUpdateMessage(completion:@escaping(ChatModelProtocol) -> Void)
    
    @discardableResult
    func createMessage(message:ChatModelProtocol) -> String?
    
    func updateMessage(payload:[String:Any],messageKey: String)
    
    func markMessageHowReaded(messageKey:String)
    
    func markMessageAsReceived(messageKey:String)
    
}


public protocol StorageManagerProtocol:class{
    
     func downloadFile(filePath: String,
                       completion:@escaping(_ url: URL?,_ error: Error?) ->Void)
    
     func uploadFile(uid: String,
                     filePath:URL,
                     completion:@escaping(_ downloadURL: URL?) -> Void)
    
    func uploadFile(userId: String,
                    filePath:URL,
                    progress:@escaping(Progress?) -> Void,
                    completion:@escaping(_ downloadURL: URL?) -> Void)
    
    @discardableResult
    func saveLocalMultimedia(url: URL, with key:String) -> URL?
}



public protocol ChannelManagerProtocol:class{
    
    var type: ChannelType {get}
        
    var coreSettings:CoreChatSettings {get set}
    
    var myUid:String {get set}
    
    @discardableResult func createRoom(channelPayload:ChannelModelProtocol) -> ChannelModelProtocol
        
    func observerChangesInChannels(completion:@escaping(ChannelModelProtocol) ->Void)
    
    func channelCollectionIsEmpty(completion:@escaping(Bool) -> Void)
    
    func observerNewChannels(completion:@escaping(ChannelModelProtocol) ->Void)
    
    func observerStatusChannel(completion: @escaping(_ closeChannel: Bool) -> Void)
    
    func updateAvatar(filePath:String)
    
    func getAvatar(avatarId:String,completion:@escaping(_ url: URL?) -> Void)
    
    func setRoomRating(keyIssue: String, rateStars: Int, rateComments: String)
    
    func registerPushToken(token:String)
    
    func changeUser(newUserId:String)
    
    func markAllMessagesReaded(channel: ChannelModelProtocol)

}


public protocol CoreChatSettings: class{
    
    var firebaseDataBase:String {get set}
    var firebaseBucket:String {get set}
}
