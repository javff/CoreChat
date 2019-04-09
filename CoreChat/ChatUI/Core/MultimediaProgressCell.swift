//
//  MultimediaProgressCell.swift
//  CoreChat
//
//  Created by Juan  Vasquez on 2/13/19.
//  Copyright © 2019 com.anincubator. All rights reserved.
//

import UIKit
import Common
import MessageKit

public enum MultimediaProgressType{
    
    case upload
    case download
}

public protocol MultiemdiaProgressDelegate:class{
    
    func multimediaProgress(_ messageCollectionView:MessagesCollectionView,
                            update indexPath:IndexPath,
                            with type:MultimediaProgressType,
                            taskProgressNotification: @escaping () -> Void)
    
    func multimediaProgress(_ messageCollectionView:MessagesCollectionView,
                            initOperation indexPath: IndexPath) -> Bool
    
    func multimediaProgress(_ messageCollectionView:MessagesCollectionView,
                            multimediaType indexPath: IndexPath) -> MultimediaProgressType
    
    func multimediaProgress(_ messageCollectionView:MessagesCollectionView,
                            canRetry indexPath: IndexPath) -> Bool
    
    func multimediaProgress(_ messageCollectionView:MessagesCollectionView,
                            retryOperation indexPath: IndexPath)
    
    func multimediaProgress(_ messageCollectionView:MessagesCollectionView,
                            taskProgressCount indexPath: IndexPath) -> Double?
    
}


open class MultimediaProgressCell: MessageContentCell {
    
    let backgroundImage = UIImageView()
    public var progressBar: UIProgressView!
    private var retryButton: UIButton!
    
    weak var customDelegate:MultiemdiaProgressDelegate?
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    open override func setupSubviews() {
        super.setupSubviews()
        
        retryButton = UIButton(frame: .zero)
        
        progressBar = UIProgressView(frame: .zero)
        progressBar.progressTintColor = UIColor.principalAppColor
        progressBar.trackTintColor = .white
        
        backgroundImage.image =  UIImage.imageWithColor(color: .white)
        backgroundImage.contentMode = .scaleAspectFill
        backgroundImage.layer.masksToBounds = true
        backgroundImage.backgroundColor = .white
        
        messageContainerView.addSubview(backgroundImage)
        backgroundImage.translatesAutoresizingMaskIntoConstraints = false
        backgroundImage.topAnchor.constraint(equalTo: messageContainerView.topAnchor).isActive = true
        backgroundImage.bottomAnchor.constraint(equalTo: messageContainerView.bottomAnchor).isActive = true
        backgroundImage.widthAnchor.constraint(equalTo: messageContainerView.widthAnchor).isActive = true
        
        backgroundImage.addSubview(retryButton)
        retryButton.translatesAutoresizingMaskIntoConstraints = false
        retryButton.centerXAnchor.constraint(equalTo: backgroundImage.centerXAnchor).isActive = true
        retryButton.centerYAnchor.constraint(equalTo: backgroundImage.centerYAnchor).isActive = true
        retryButton.widthAnchor.constraint(equalToConstant: 20).isActive = true
        retryButton.heightAnchor.constraint(equalToConstant: 20).isActive = true
        
        backgroundImage.addSubview(progressBar)
        progressBar.translatesAutoresizingMaskIntoConstraints = false
        progressBar.trailingAnchor.constraint(equalTo: backgroundImage.trailingAnchor).isActive = true
        progressBar.leadingAnchor.constraint(equalTo: backgroundImage.leadingAnchor).isActive = true
        progressBar.bottomAnchor.constraint(equalTo: backgroundImage.bottomAnchor).isActive = true
        progressBar.heightAnchor.constraint(equalToConstant: 4).isActive = true
        
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        backgroundImage.frame = contentView.bounds
        
        
    }
    
    open override func handleTapGesture(_ gesture: UIGestureRecognizer) {
        
        //FIX: MANEJAR SOLO TAP GESTURE DEL BOTON RETRY //
        
        // retry tap gesture recnoizer //
        
        guard let collectionView = self.superview as? MessagesCollectionView else{
            return
        }
        
        guard let indexPath = collectionView.indexPath(for: self) else{
            return
        }
        
        guard let canRetry = self.customDelegate?.multimediaProgress(collectionView, canRetry: indexPath) else{
            return
        }
        
        if !canRetry{return}
        
        self.customDelegate?.multimediaProgress(collectionView, retryOperation: indexPath)
        
        
    }
    
    private func configureItemsCell(uploadFailed:Bool,type:MultimediaProgressType){
        
        if uploadFailed{
            self.handlerFailedNotification()
        }else{
            self.uploadInitUpdateUI(type: type)
        }
    }
    
    private func handlerFailedNotification(){
        
        let bundle = Bundle(for:MultimediaProgressCell.self)
        let retryImage = UIImage(named: "retry", in:bundle , compatibleWith: nil)
        
        UIView.animate(withDuration: 0.2) {
            self.progressBar.alpha = 0
            self.retryButton.setImage(retryImage,for: .normal)
            
        }
    }
    
    private func uploadInitUpdateUI(type: MultimediaProgressType){
        
        
        let image = type == MultimediaProgressType.upload ? "upload" : "download"
        let bundle = Bundle(for:MultimediaProgressCell.self)
        let retryImage = UIImage(named: image, in:bundle , compatibleWith: nil)
        
        UIView.animate(withDuration: 0.2) {
            self.progressBar.alpha = 1
            self.retryButton.setImage(retryImage,for: .normal)
        }
    }
    
    private func updateProgress(indexPath: IndexPath, and messagesCollectionView: MessagesCollectionView){
        
        guard let progressCount = self.customDelegate?.multimediaProgress(messagesCollectionView,
                                                                          taskProgressCount: indexPath) else{
                                                                            return
        }
        
        
        self.progressBar.setProgress(Float(progressCount), animated: true)
    }
    
    
    open override func configure(with message: MessageType, at indexPath: IndexPath, and messagesCollectionView: MessagesCollectionView) {
        
        super.configure(with: message, at: indexPath, and: messagesCollectionView)
        
        guard let canRetryInstruction = self.customDelegate?.multimediaProgress(messagesCollectionView,
                                                                                canRetry: indexPath) else{
                                                                                    return
        }
        
        guard let initOperationInstruction = self.customDelegate?.multimediaProgress(messagesCollectionView, initOperation: indexPath) else{
            return
        }
        
        guard let multimediaTypeOperation = self.customDelegate?.multimediaProgress(messagesCollectionView,
                                                                                    multimediaType: indexPath) else{
                                                                                        return
        }
        
        if let currentProgress = self.customDelegate?.multimediaProgress(messagesCollectionView,
                                                                         taskProgressCount: indexPath){
            
            self.progressBar.setProgress(Float(currentProgress), animated: false)
        }else{
            self.progressBar.setProgress(0, animated: false)
        }
        
        self.configureItemsCell(uploadFailed: canRetryInstruction,type: multimediaTypeOperation)
        
        if initOperationInstruction{
            
            self.customDelegate?.multimediaProgress(messagesCollectionView, update: indexPath, with: multimediaTypeOperation, taskProgressNotification: {
                
                self.updateProgress(indexPath: indexPath, and: messagesCollectionView)
                
            })
        }
    }
    
}
