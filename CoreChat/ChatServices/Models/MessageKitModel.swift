//
//  MessageKitModel.swift
//  CoreChat
//
//  Created by Juan  Vasquez on 2/11/19.
//  Copyright © 2019 com.anincubator. All rights reserved.
//

import Foundation
import CoreLocation
import MessageKit
import AVKit

public class MessageKitModel:MessageType{
    
    public var kind: MessageKind
    public var messageId: String
    public var sender: Sender
    public var sentDate: Date
    public var payload: ChatModelProtocol
    
    public init(sender: Sender,payload: ChatModelProtocol) {
        
        self.kind = MessageKitModel.kindType(payload: payload)
        self.sender = sender
        self.payload = payload
        self.messageId = UUID.init().uuidString
        self.sentDate = payload.date ?? Date()
        
    }
    
    
    private static func kindType(payload: ChatModelProtocol) -> MessageKind{
        
        if payload.type! == .text{
            return MessageKind.text(payload.message)
        }
        
        if payload.type! == .lesson {
            return MessageKind.custom(payload.type!.rawValue)
        }
        
        if payload.type! != .text{
            
            // detecting upload or download type
            
            if payload.isDownloadType() || payload.isUploadType(){
                
                return MessageKind.custom(payload.type!.rawValue)
                
            }else{
                // detecting multimedia types //
                switch payload.type! {
                    
                case .audio:
                    
                    let audioAsset = AVAsset(url:  payload.localResource!)
                    let duration = audioAsset.duration
                    let durationTime = Float(CMTimeGetSeconds(duration))
                    
                    let audioItem = AudioMessageItem(url: payload.localResource!,
                                                     duration: durationTime)
                    
                    return MessageKind.audio(audioItem)
                    
                case .image:
                    
                    let imageData = try! Data.init(contentsOf: payload.localResource!)
                    let image = UIImage.init(data: imageData)!
                    let imageItem = ImageItem(url:nil,image:image,placeholderImage:image)
                    return MessageKind.photo(imageItem)
                    
                case .file:
                    return MessageKind.custom(payload.type!.rawValue)
                    
                    
                default:
                    //TODO: Verificar porque cae en este caso a veces
                    return MessageKind.text("")
                }
            }
            
        }
        return MessageKind.text("tipo de mensaje no soportado")
    }
    
}


//MARK: - helpers class

public class ImageItem: MediaItem{
    
    public var url: URL?
    
    public var image: UIImage?
    
    public var placeholderImage: UIImage
    
    public var size: CGSize
    
    
    public init(url:URL?,image:UIImage,placeholderImage:UIImage){
        
        let size = UIScreen.main.bounds.width / 1.5
        
        self.size = CGSize(width: size, height: size)
        self.placeholderImage = placeholderImage
        self.image = image
        self.url = url
    }
    
}


public class AudioMessageItem: AudioItem{
    
    public var url: URL
    public var duration: Float
    public var size: CGSize
    
    init(url:URL, duration:Float){
        self.url = url
        self.duration = duration
        let width = UIScreen.main.bounds.width / 1.5
        self.size =  CGSize(width: width, height: 60)
    }
}

