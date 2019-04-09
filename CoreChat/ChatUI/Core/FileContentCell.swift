//
//  FileContentCell.swift
//  CoreChat
//
//  Created by Juan  Vasquez on 2/13/19.
//  Copyright © 2019 com.anincubator. All rights reserved.
//


import UIKit
import MessageKit

public protocol FileContentCellDataSource:class{
    
    func messageCollectionView(_ messagesCollectionView: MessagesCollectionView, cell:FileContentCell, fileName at:IndexPath) -> String
    
    func messageCollectionView(_ messagesCollectionView: MessagesCollectionView, cell:FileContentCell, fileType at:IndexPath) -> String
    
}


open class FileContentCell: MessageContentCell {
    
    
    let typeLabel:UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.textAlignment = .left
        label.font = UIFont.systemFont(ofSize: 12)
        return label
    }()
    
    let nameLabel:UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.font = UIFont.systemFont(ofSize: 14)
        label.textAlignment = .left
        return label
    }()
    
    weak var dataSource:FileContentCellDataSource?
    
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    open override func setupSubviews() {
        super.setupSubviews()
        
        let imageView = UIImageView()
        let bundle = Bundle(for:ChatViewController.self)
        let fileImage = UIImage(named: "file", in:bundle , compatibleWith: nil)
        imageView.image = fileImage
        imageView.contentMode = .scaleAspectFit
        
        messageContainerView.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.leadingAnchor.constraint(equalTo: messageContainerView.leadingAnchor,constant:5).isActive = true
        imageView.topAnchor.constraint(equalTo: messageContainerView.topAnchor,constant:10).isActive = true
        imageView.bottomAnchor.constraint(equalTo: messageContainerView.bottomAnchor,constant:-10).isActive = true
        imageView.widthAnchor.constraint(equalToConstant: 50).isActive = true
        
        messageContainerView.addSubview(nameLabel)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.leadingAnchor.constraint(equalTo: imageView.trailingAnchor).isActive = true
        nameLabel.trailingAnchor.constraint(equalTo: messageContainerView.trailingAnchor,constant:-10).isActive = true
        nameLabel.centerYAnchor.constraint(equalTo: messageContainerView.centerYAnchor).isActive = true
        
        messageContainerView.addSubview(typeLabel)
        typeLabel.translatesAutoresizingMaskIntoConstraints = false
        typeLabel.bottomAnchor.constraint(equalTo: messageContainerView.bottomAnchor).isActive = true
        typeLabel.leadingAnchor.constraint(equalTo: imageView.leadingAnchor,constant: 15).isActive = true
        
        
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    
    open override func configure(with message: MessageType, at indexPath: IndexPath, and messagesCollectionView: MessagesCollectionView) {
        super.configure(with: message, at: indexPath, and: messagesCollectionView)
        
        guard let datasource = self.dataSource else{
            fatalError("You must implement datasource")
        }
        
        guard let displayDelegate = messagesCollectionView.messagesDisplayDelegate else {
            fatalError("You must implement display delegate")
        }
        
        let fileName = datasource.messageCollectionView(messagesCollectionView, cell: self, fileName: indexPath)
        
        let fileType = datasource.messageCollectionView(messagesCollectionView, cell: self, fileType: indexPath)
        
        let textColor = displayDelegate.textColor(for: message, at: indexPath, in: messagesCollectionView)
        self.nameLabel.textColor = textColor
        self.typeLabel.textColor = textColor
        self.nameLabel.text = fileName
        self.typeLabel.text = fileType
        
    }
    
}
