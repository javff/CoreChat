//
//  ChatMessageModel.swift
//  CoreChat
//
//  Created by Juan  Vasquez on 2/12/19.
//  Copyright © 2019 com.anincubator. All rights reserved.
//

import Foundation
import ObjectMapper


public enum ChatMessageType:String{
    
    case text = "text"
    case image = "image"
    case video = "video"
    case audio = "audio"
    case file = "file"
    case lesson = "lesson"
    case unkown
    
}


public class ChatMessageModel:Mappable,ChatModelProtocol{
    
    public var key = ""{
        didSet{
            if type != .text{
                self.localResource = self.searchCacheFile()
            }
        }
    }
    
    public var timestamp = 0 {
        
        didSet{
            self.date = Date(timeIntervalSince1970: TimeInterval(timestamp / 1000))
        }
    }
    
    private var internalType = ""{
        didSet{
            let type = ChatMessageType.init(rawValue: internalType.lowercased()) ?? .unkown
            self.type = type
        }
    }
    
    public var uid = ""
    public var iosID: String?
    public var type: ChatMessageType?
    public var link = ""
    public var message = ""
    public var rol = ""
    public var userId = ""
    public var date: Date?
    public var localResource:URL?
    public var mimeType:String?
    public var statusReaded:Bool = false
    public var readedTimestamp:TimeInterval = 0{
        didSet{
            self.readedTimestamp = TimeInterval(readedTimestamp / 1000)
        }
    }
    public var receivedTimestamp:TimeInterval = 0{
        didSet{
            self.receivedTimestamp = TimeInterval(receivedTimestamp / 1000)
        }
    }
    public var operationFailed:Bool = false{
        didSet{
            if operationFailed{
                self.taskProgress = nil
            }
        }
    }
    public var taskProgress:Progress?
    
    public init(timestamp:Int, uid:String, iosID: String, type:String, link:String, message: String, rol:String, userId:String, mimeType mime:String? = nil){
        
        self.timestamp = timestamp
        self.uid = uid
        self.iosID = iosID
        self.internalType = type
        self.link = link
        self.message = message
        self.rol = rol
        self.userId = userId
        self.mimeType = mime
        let type = ChatMessageType.init(rawValue: internalType.lowercased()) ?? .unkown
        self.type = type
        
        if isFileType() {
            self.localResource = self.searchCacheFile()
        }
    }
    
    
    //MARK: - Messages funcs
    
    public func markHowReaded(){
        
    }
    
    private func isFileType() -> Bool {
        return self.type == .image ||
            self.type == .video ||
            self.type == .audio ||
            self.type == .file
    }
    
    //*** verifica que un mensaje multimedia este listo para ser mostrado (Valida logica en android) //
    public func isNotYetForDisplay() ->Bool{
        return self.isFileType() && self.localResource == nil && self.link.isEmpty
    }
    
    public func isDownloadType() -> Bool{
        return self.isFileType() && self.localResource == nil && !self.link.isEmpty
    }
    
    public func isUploadType() -> Bool{
        return self.isFileType() && self.localResource != nil && self.link.isEmpty
    }
    
    
    public func downloadMultimedia(progressHandler:@escaping(_ progress: Progress) ->Void,
                                   completion: @escaping (_ localURL: URL?) -> Void){
        
        
        guard let url = URL(string:self.link) else{
            completion(nil)
            return
        }
        
        var destinationUrl: URL = FileManager.default.urls(for: .documentDirectory,
                                                           in: .userDomainMask).first!
        let format = url.pathExtension
        
        destinationUrl.appendPathComponent(self.key + ".\(format)")
        
        Downloader.downloadFile(to: url, save: destinationUrl, progressHandler: { (progres) in
            
            progressHandler(progres)
            
        }) { (destinationURL) in
            
            self.localResource = destinationURL
            completion(destinationUrl)
            
        }
    }
    
    private func searchCacheFile() -> URL?{
        
        
        let destinationUrl: URL = FileManager.default.urls(for: .documentDirectory,
                                                           in: .userDomainMask).first!
        
        let documents =  try! FileManager.default.contentsOfDirectory(at: destinationUrl,
                                                                      includingPropertiesForKeys: nil)
        
        
        let index = documents.index { (url) -> Bool in
            return url.lastPathComponent.contains(self.key)
        }
        
        
        if let index = index{
            self.localResource = documents[index]
        }
        
        return self.localResource
        
    }
    
    //MARK: - Mapping
    
    public required init?(map: Map) {
        
    }
    
    public func mapping(map: Map) {
        
        timestamp <- map["timestamp"]
        uid <- map["uid"]
        iosID <- map["iosID"]
        internalType <- map["type"]
        link <- map["link"]
        message <- map["message"]
        rol <- map["rol"]
        userId <- map["userId"]
        statusReaded <- map["statusReaded"]
        readedTimestamp <- map["readedTimestamp"] // Marca de tiempo de cuando se LEE el mensaje
        receivedTimestamp <- map["receivedTimestamp"] // Marca de tiempo de cuando se RECIBE el mensaje
        mimeType <- map["mimeType"]
    }
    
    
    
}
