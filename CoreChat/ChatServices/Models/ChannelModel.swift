//
//  ChannelModel.swift
//  CoreChat
//
//  Created by Juan  Vasquez on 2/12/19.
//  Copyright © 2019 com.anincubator. All rights reserved.
//

import Foundation
import ObjectMapper
import MessageKit

public class ChannelModel: Mappable, ChannelModelProtocol{

    public var key: String?
    public var channelName: String = ""
    public var unreadMessageCount: Int = 0
    public var lastMessage: ChatModelProtocol?
    public var participantId: String = ""{
        didSet{
            participantId = participantId.replacingOccurrences(of: ".", with: "%")
        }
    }
    public var lastUpdateTimestamp: TimeInterval = 0
    
    
    public required init(channelName: String, lastUpdateTimestamp: TimeInterval, participantId:String) {
        self.channelName = channelName
        self.lastUpdateTimestamp = lastUpdateTimestamp
        self.participantId = participantId.replacingOccurrences(of: ".", with: "%")
    }
    
    required public init?(map: Map) {
        
        if let lastMessageJSON = map.JSON["lastMessage"] as? [String: Any]{
            lastMessage = Mapper<ChatMessageModel>().map(JSON: lastMessageJSON)
        }
    }
    
    public func mapping(map: Map) {
        
        channelName <- map["channelName"]
        lastUpdateTimestamp <- map["lastUpdateTimestamp"]
        participantId <- map["participantId"]
        unreadMessageCount <- map["unreadMessageCount"]
    }
}
