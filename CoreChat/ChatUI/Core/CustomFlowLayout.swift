//
//  CustomFlowLayout.swift
//  CoreChat
//
//  Created by Juan  Vasquez on 2/13/19.
//  Copyright © 2019 com.anincubator. All rights reserved.
//

import Foundation
import MessageKit

open class CustomMessagesFlowLayout: MessagesCollectionViewFlowLayout {
    lazy open var customMessageSizeCalculator = CustomMessageSizeCalculator(layout: self)
    
    override open func cellSizeCalculatorForItem(at indexPath: IndexPath) -> CellSizeCalculator {
        let message = messagesDataSource.messageForItem(at: indexPath, in: messagesCollectionView)
        if case .custom = message.kind {
            return customMessageSizeCalculator
        }
        return super.cellSizeCalculatorForItem(at: indexPath);
    }
}

open class CustomMessageSizeCalculator: MessageSizeCalculator {
    
    open override func cellBottomLabelAlignment(for message: MessageType) -> LabelAlignment {
        let dataSource = messagesLayout.messagesDataSource
        let isFromCurrentSender = dataSource.isFromCurrentSender(message: message)
        let outgoingBottomAllignment = LabelAlignment(textAlignment: .right, textInsets: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 3))
        let incomingBottomAlignment = LabelAlignment(textAlignment: .left, textInsets: UIEdgeInsets(top: 0, left: 3, bottom: 0, right: 0))
        
        return isFromCurrentSender ? outgoingBottomAllignment : incomingBottomAlignment
    }
    
    
    open override func avatarSize(for message: MessageType) -> CGSize {
        return .zero
    }
    
    open override func messageContainerSize(for message: MessageType) -> CGSize {
        //MARK - Customize to size your content appropriately. This just returns a constant size.
        switch message.kind {
            
        case .custom(let data):
            
            guard let stringType = data as? String else{
                return .zero
            }
            
            guard let messageType = ChatMessageType(rawValue: stringType) else{
                return .zero
            }
            
            switch messageType{
                
            case .audio:
                let width = UIScreen.main.bounds.width / 1.5
                return CGSize(width: width, height: 60)
                
            case .image:
                let size = UIScreen.main.bounds.width / 1.5
                return CGSize(width: size, height: size)
                
            case .file:
                let width = UIScreen.main.bounds.width / 1.5
                return CGSize(width: width, height: 60)
                
            case .lesson:
                let width = UIScreen.main.bounds.width / 1.5
                return CGSize(width: width, height: 60)
                
            default:
                return .zero
                
            }
            
        default:
            return .zero
        }
    }
}
