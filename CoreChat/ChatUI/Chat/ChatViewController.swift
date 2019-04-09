//
//  ChatViewController.swift
//  CoreChat
//
//  Created by Juan  Vasquez on 2/13/19.
//  Copyright © 2019 com.anincubator. All rights reserved.
//

import UIKit
import MessageKit
import AVFoundation
import Photos
import SDWebImage
import Common
import iOSPhotoEditor
import MessageInputBar
import MobileCoreServices

public class ChatViewController: MessagesViewController {
    
    
    //MARK: - Dependecy Inyections //
    let channel: ChannelModelProtocol
    let channelManager:ChannelManagerProtocol
    let chatManager:ChatManagerProtocol
    
    //MARK: - Document Vars
    let documentInteractionController = UIDocumentInteractionController()
    
    //MARK: - audio recording vars
    open lazy var audioController = BasicAudioController(messageCollectionView: messagesCollectionView)
    
    var recordingSession: AVAudioSession!
    var audioRecorder: AVAudioRecorder!
    var audioFileName: URL!
    
    //MARK: - UI Vars
    //TODO: - Disable more message indicator
//    var moreMessageIndicatorBottomAnchor: NSLayoutConstraint!
//    var rateBottomAnchor: NSLayoutConstraint!
//
//    fileprivate lazy var moreMessageIndicator: UIView = {
//
//        let view = UIView(frame: .zero)
//
//        view.backgroundColor = UIColor.principalAppColor
//        view.alpha = 0
//
//        let scrollTapButton = UITapGestureRecognizer(target: self, action: #selector(self.scrollTapButtonTapped))
//        view.addGestureRecognizer(scrollTapButton)
//        view.addSubview(self.counterIndicator)
//        return view
//
//    }()
    
    fileprivate lazy var counterIndicator: UILabel = {
        
        let rect = CGRect(x: 12, y: 12, width: 20, height: 20)
        let label = UILabel(frame: rect)
        label.text = "↓"
        label.textAlignment = .center
        label.font = UIFont.boldSystemFont(ofSize: 17)
        label.textColor = .white
        return label
        
    }()
    
    fileprivate var counterIndicatorNumber:Int = 0 {
        
        didSet{
            counterIndicator.text = counterIndicatorNumber == 0 ? "↓" : "\(counterIndicatorNumber)"
        }
    }
    
    
    private var activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: 60, height: 60)))
    
    
//    private lazy var rateChatCell: RateChatCell = RateChatCell.instanceFromNib()
    
    
    var mockMessages:[MessageKitModel] = []
    
    lazy var sender =  Sender(id: channelManager.myUid, displayName: "displayName")
    
    var issue = UUID().uuidString
    
    var activeIssue = true{
        
        didSet{
            self.detectingCloseIssue()
        }
    }
    
    var canSendAudio = false
    var isRecordingAudio = false
    
    lazy var formatter: DateFormatter = {
        let formatter = DateFormatter()
        
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
    
    //MARK: - life cycle
    
    public init(channel: ChannelModelProtocol,
                channelManager: ChannelManagerProtocol,
                chatManager:ChatManagerProtocol) {
        
        self.channel = channel
        self.channelManager = channelManager
        self.chatManager = chatManager
        super.init(nibName: nil, bundle: nil)
        self.messageInputBar = WehpahMessageBar()
        
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func viewDidLoad() {
        self.setupCustomCell()
        super.viewDidLoad()
        
        self.setupView()
        
        // permissons /
        self.audioPermissons()
        
        // set delegates //
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messagesCollectionView.messageCellDelegate = self
        messageInputBar.delegate = self
        documentInteractionController.delegate = self
//        rateChatCell.delegate = self
        
        if let customInputBar = messageInputBar as? WehpahMessageBar{
            customInputBar.hooksDelegate = self
        }
        
        self.messageInputBar.inputTextView.autocorrectionType = .no
        
        self.detectingCloseIssue()
        self.observeMessages()
        
    }
    
    
    
    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow), name: .UIKeyboardWillShow, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide(_:)), name: .UIKeyboardWillHide, object: nil)
        
    }
    
    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.messageInputBar.alpha = 1
    }
    
    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.messageInputBar.inputTextView.resignFirstResponder()
        self.messageInputBar.alpha = 0
        
        // remove all UI observers
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillHide, object: nil)
        
        //Stop playing
        audioController.stopAnyOngoingPlaying()
    }
    
    
    //MARK: - setups
    
    private func setupCustomCell(){
        
        messagesCollectionView = MessagesCollectionView(frame: .zero, collectionViewLayout:  CustomMessagesFlowLayout())
        messagesCollectionView.register(MultimediaProgressCell.self)
        messagesCollectionView.register(FileContentCell.self)
      //  messagesCollectionView.register(LessonContentCell.self)
        
    }
    
    private func setupView(){
        
        messageInputBar.inputTextView.placeholder = "Write your message"
        messageInputBar.isHidden = true
        messageInputBar.isHidden = false
        messageInputBar.backgroundColor = .white
        messageInputBar.inputTextView.backgroundColor = UIColor.lightGrayApp
        
        let backgroundView = UIView(frame: self.view.frame)
        backgroundView.backgroundColor = UIColor.lightGrayApp
        let imageView = UIImageView()
        
        imageView.image = UIImage(named: "wehpahLogo")!
        imageView.contentMode = .scaleAspectFit
        imageView.layer.masksToBounds = true
        
        backgroundView.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.tintColor = UIColor.principalAppColor
        imageView.widthAnchor.constraint(equalToConstant: 200).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: 200).isActive = true
        imageView.centerXAnchor.constraint(equalTo: backgroundView.centerXAnchor).isActive = true
        imageView.centerYAnchor.constraint(equalTo: backgroundView.centerYAnchor).isActive = true
        
        self.messagesCollectionView.backgroundView = backgroundView
        self.title = self.channel.channelName
        
        // add MoreMessage indicatorView //
        //MARK: - Disable more message indicator
//        self.view.addSubview(self.moreMessageIndicator)
//        self.moreMessageIndicator.translatesAutoresizingMaskIntoConstraints = false
//        moreMessageIndicatorBottomAnchor = self.moreMessageIndicator.bottomAnchor.constraint(equalTo: view.bottomAnchor,constant: -40)
//        moreMessageIndicatorBottomAnchor.isActive = true
//        self.moreMessageIndicator.trailingAnchor.constraint(equalTo: view.trailingAnchor,constant: -5).isActive = true
//        self.moreMessageIndicator.widthAnchor.constraint(equalToConstant: 45).isActive = true
//        self.moreMessageIndicator.heightAnchor.constraint(equalToConstant: 45).isActive = true
//        self.moreMessageIndicator.layer.cornerRadius = 22.5
//        self.moreMessageIndicator.layer.masksToBounds = true
        
        // add rate chat view //
//        self.view.addSubview(rateChatCell)
//        self.rateChatCell.translatesAutoresizingMaskIntoConstraints = false
//        self.rateBottomAnchor = rateChatCell.bottomAnchor.constraint(equalTo: view.bottomAnchor,constant:0)
//        rateBottomAnchor.isActive = true
//        self.rateChatCell.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
//        self.rateChatCell.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
//        self.rateChatCell.heightAnchor.constraint(equalToConstant: 200).isActive = true
        
        // set avatar size //
        let layout = messagesCollectionView.collectionViewLayout as? MessagesCollectionViewFlowLayout
        
        layout?.setMessageOutgoingAvatarSize(.zero)
        layout?.setMessageIncomingAvatarSize(.zero)
        
        let outgoingBottomAllignment = LabelAlignment(textAlignment: .right, textInsets: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 3))
        layout?.setMessageOutgoingCellBottomLabelAlignment(outgoingBottomAllignment)
        
        let incomingBottomAlignment = LabelAlignment(textAlignment: .left, textInsets: UIEdgeInsets(top: 0, left: 3, bottom: 0, right: 0))
        layout?.setMessageIncomingCellBottomLabelAlignment(incomingBottomAlignment)
        
    }
    
    //MARK: - funcs
    
    @objc func scrollTapButtonTapped(){
        
        self.scrollBottomWithNotification()
        
    }
    
    @objc func tapGestureRecognizer(){
        
        self.messageInputBar.inputTextView.resignFirstResponder()
        
    }
    
    func detectingCloseIssue(){
        if !self.activeIssue{
            //            self.navigationItem.title = "Insidencia cerrada"
            self.messageInputBar.isHidden = true
          //  self.rateChatCell.isHidden = false
        } else {
         //   self.rateChatCell.isHidden = true
        }
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {
        
        if let keyboardFrame: NSValue = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRectangle = keyboardFrame.cgRectValue
            let keyboardHeight = keyboardRectangle.height
            
            let isInLastScroll = self.isLastSectionVisible()
            
            if  isInLastScroll{
                self.scrollBottomWithNotification()
            }
            
//            if keyboardHeight >= 100{
//                self.moreMessageIndicatorBottomAnchor.constant -= (keyboardHeight - 35)
//            //    self.rateBottomAnchor.constant -= (keyboardHeight)
//            }
            
            UIView.animate(withDuration: 0.25) {
              //  self.view.layoutIfNeeded()
            }
            
        }
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        
      //  self.moreMessageIndicatorBottomAnchor.constant = -45
       // self.rateBottomAnchor.constant = 0
        
        UIView.animate(withDuration: 0.15) {
            self.view.layoutIfNeeded()
        }
    }
    
    //MARK: - firebase methods
    
    private func observeMessages() {
        
        // detecting close issue //
        
        self.channelManager.observerStatusChannel {[weak self] (isChannelClosed) in
            
            guard let weakSelf = self else{
                return
            }
            
            weakSelf.activeIssue = isChannelClosed
        }
        
        // detecting new messages added //
        self.chatManager.observerMessages {[weak self] (message) in

            guard let weakSelf = self else{
                return
            }

            if message.isNotYetForDisplay(){
                return
            }

            let senderId = message.userId.replacingOccurrences(of: ".", with: "%")

            let sender = Sender(id: senderId, displayName: "displayName")
            
            let mockMessage = MessageKitModel(sender: sender,payload: message)

            // TODO: No se deben marcar como leídos aquí, deben marcarse cuando aparezcan en pantalla
            if sender != weakSelf.currentSender() && message.readedTimestamp == 0 {
                weakSelf.chatManager.markMessageHowReaded(messageKey: message.key)
            }

            if sender != weakSelf.currentSender() && message.receivedTimestamp == 0 {
                weakSelf.chatManager.markMessageAsReceived(messageKey: message.key)
            }
            
            //mark all messages readed //
            if sender != weakSelf.currentSender(){
                weakSelf.channelManager.markAllMessagesReaded(channel: weakSelf.channel)
            }

            weakSelf.addMessage(mediaItem: mockMessage)

            if sender.id != weakSelf.sender.id{
                weakSelf.counterIndicatorNumber += 1
            }
        }
        
        // detecting last update message //
        
        self.chatManager.observerLastUpdateMessage {[weak self] (updateMessage) in
            
            guard let weakSelf = self else{
                return
            }
            
            let index = weakSelf.mockMessages.firstIndex(where: { (message) -> Bool in
               
                return updateMessage.key == message.payload.uid && !message.payload.uid.isEmpty
            })
            
            let sender = Sender(id: updateMessage.userId, displayName: "displayName")
            
            let message = MessageKitModel(sender: sender, payload: updateMessage)

            if let index = index{
                
                weakSelf.mockMessages[index] = message
               
                DispatchQueue.main.async {
                    weakSelf.messagesCollectionView.reloadItems(at: [IndexPath(item: 0, section: index)])
                }
            }else if !updateMessage.isNotYetForDisplay(){
                weakSelf.addMessage(mediaItem: message)
            }
        }
    }
    
    func uploadMultimediaFile(url:URL, type: ChatMessageType){
        
        // add upload Message //
        let payload = ChatMessageModel(timestamp: Int(Date().timeIntervalSince1970 * 1000),
                                       uid: "",
                                       iosID: UUID.init().uuidString,
                                       type: type.rawValue,
                                       link: "",
                                       message: "",
                                       rol: "client",
                                       userId: self.sender.id)
        
        payload.localResource = url
        let message = MessageKitModel(sender: self.sender, payload: payload)
        self.addMessage(mediaItem: message)
    }
    
    func uploadMultimediaFileWith(mimeType:String,url:URL, type: ChatMessageType){
        
        let payload = ChatMessageModel(timestamp: Int(Date().timeIntervalSince1970 * 1000),
                                       uid: "",
                                       iosID: UUID.init().uuidString,
                                       type: type.rawValue,
                                       link: "",
                                       message: "",
                                       rol: "client",
                                       userId: self.sender.id,
                                       mimeType:mimeType)
        
        payload.localResource = url
        let message = MessageKitModel(sender: self.sender, payload: payload)
        self.addMessage(mediaItem: message)
        
    }
    
    func sendMultimediaMessage(resourceURL:String,localURL:URL, message: ChatModelProtocol){
        
        let fileName = localURL.lastPathComponent
        
        let message = ChatMessageModel(
            timestamp: Int(Date().timeIntervalSince1970 * 1000),
            uid: "",
            iosID: message.iosID ?? "",
            type: message.type?.rawValue ?? "",
            link:  resourceURL,
            message: message.type == .file ? fileName : message.message,
            rol:"client",
            userId: self.sender.id,
            mimeType: message.mimeType)
        
        
        guard let messageKey = self.chatManager.createMessage(message: message) else{
            return
        }
        
        // caching local URL //
        
        let storage = self.chatManager.storage
        let format = localURL.pathExtension
        storage.saveLocalMultimedia(url: localURL, with: "\(messageKey).\(format)")

    }
    
    func sendTextMessage(message:String, uuid:String){
        
        let message = ChatMessageModel(
            timestamp: Int(Date().timeIntervalSince1970 * 1000),
            uid: "",
            iosID: UUID.init().uuidString,
            type: ChatMessageType.text.rawValue,
            link: "",
            message: message,
            rol:"client",
            userId: self.sender.id)
        
        self.chatManager.createMessage(message: message)
        
    }
    
    //MARK: - helpers
    
    func addMessage(mediaItem: MessageKitModel) {
        
        let index = self.mockMessages.firstIndex { (message) -> Bool in

            let receivedCondition = (message.payload.uid == mediaItem.payload.uid &&  !mediaItem.payload.uid.isEmpty)

            guard let receiveIosID = mediaItem.payload.iosID else{
                return receivedCondition
            }

            guard let searchingIosID = message.payload.iosID else{
                return  receivedCondition
            }

            return (receiveIosID == searchingIosID)

        }

        if let index = index{
            self.mockMessages[index] = mediaItem
            let indexPath = IndexPath(item: 0, section: index)
            self.messagesCollectionView.reloadItems(at: [indexPath])

        }else{

            mockMessages.append(mediaItem)

            messagesCollectionView.performBatchUpdates({

                messagesCollectionView.insertSections([mockMessages.count - 1])

                if mockMessages.count >= 2 {
                    messagesCollectionView.reloadSections([mockMessages.count - 2])
                }

            }, completion: { [weak self] _ in

                guard let strongSelf = self else{
                    return
                }

                if strongSelf.isLastSectionVisible() ||  mediaItem.sender == strongSelf.sender{
                    strongSelf.messagesCollectionView.scrollToBottom(animated: true)
                }
            })
        }
    }
    
    func isLastSectionVisible() -> Bool {
        
        guard !mockMessages.isEmpty else { return false }
        let lastIndexPath = IndexPath(item: 0, section: mockMessages.count - 1)
        return messagesCollectionView.indexPathsForVisibleItems.contains(lastIndexPath)
    }
    
    
    fileprivate func scrollBottomWithNotification(){
        self.counterIndicatorNumber = 0
        self.messagesCollectionView.scrollToBottom(animated: true)
    }
    
    
    //MARK: - prepare CollectionView for CustomCell
    
    public override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        guard let messagesDataSource = messagesCollectionView.messagesDataSource else {
            fatalError("Ouch. nil data source for messages")
        }

        let message = messagesDataSource.messageForItem(at: indexPath, in: messagesCollectionView)
        let currentPayload = self.mockMessages[indexPath.section].payload

        if case .custom = message.kind {
            
            if currentPayload.isUploadType() || currentPayload.isDownloadType() {
                let cell = messagesCollectionView.dequeueReusableCell(MultimediaProgressCell.self, for: indexPath)
                cell.customDelegate = self
                cell.configure(with: message, at: indexPath, and: messagesCollectionView)
                return cell
            }

            // if message is custom and not is MultimediaProgress, then is FileContentCell //
            let cell = messagesCollectionView.dequeueReusableCell(FileContentCell.self, for: indexPath)
            cell.dataSource = self
            cell.configure(with: message, at: indexPath, and: messagesCollectionView)
            return cell
        }
        return super.collectionView(collectionView, cellForItemAt: indexPath)
    }
    
    
    
}


//MARK: - message data source

extension ChatViewController: MessagesDataSource, FileContentCellDataSource {
    
    
    public func messageCollectionView(_ messagesCollectionView: MessagesCollectionView, cell: FileContentCell, fileName at: IndexPath) -> String {
        
        let payload = self.mockMessages[at.section].payload
        return payload.message
    }
    
    public func messageCollectionView(_ messagesCollectionView: MessagesCollectionView, cell: FileContentCell, fileType at: IndexPath) -> String {
        
        let payload = self.mockMessages[at.section].payload

        if let mimeType = payload.mimeType{
            return String(mimeType.split(separator: "/").last ?? "")
        }
        return  ""
        
    }
    
    
    public func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return mockMessages.count
    }
    
    public func currentSender() -> Sender {
        return self.sender
    }
    
    
    
    public func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return mockMessages[indexPath.section]
    }
    
    public func cellBottomLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        
        
        let message = self.mockMessages[indexPath.section]

        let received = message.payload.receivedTimestamp != 0
        let readed = message.payload.readedTimestamp != 0

        var mark = received ? "✓✓" : "✓"
        //mark = message.sended ? mark : "☉"

        mark = self.sender.id == message.sender.id ? mark : ""

        let dateString = formatter.string(from: message.sentDate)

        let markColor:UIColor =  received && readed ? .blue : .black

        return NSAttributedString(string: "\(mark) \(dateString)",
            attributes: [
                NSAttributedStringKey.font: UIFont.preferredFont(forTextStyle: .caption2),
                NSAttributedStringKey.foregroundColor: markColor
            ])
    }
}




//MARK: - message cell delegate

extension ChatViewController:MessageCellDelegate{
    
    
    public func didSelectURL(_ url: URL){
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
    
    public func didTapMessage(in cell: MessageCollectionViewCell) {
        
        if let index = self.messagesCollectionView.indexPath(for: cell){

            let message = self.mockMessages[index.section]

            switch message.kind{

            case .photo:
                
                if let url = message.payload.localResource{
                    self.storeAndShare(
                        withURLString: url.absoluteString,
                        title: message.payload.type?.rawValue ?? ""
                    )
                }
                
            case .custom(let anyType):

                guard let stringType = anyType as? String else{
                    return
                }

                guard let type = ChatMessageType.init(rawValue: stringType) else{
                    return
                }

                if type == .file{

                    guard let file = message.payload.localResource else{
                        return
                    }
                    self.storeAndShare(withURLString: file.absoluteString,
                                       title: message.payload.type?.rawValue ?? "")
                }

            default:
                break
            }
        }
    }
    
    //MARK: - audio handlers
    
    public func didTapPlayButton(in cell: AudioMessageCell) {
        
        guard let indexPath = messagesCollectionView.indexPath(for: cell),
            let message = messagesCollectionView.messagesDataSource?.messageForItem(at: indexPath, in: messagesCollectionView) else {
                print("Failed to identify message when audio cell receive tap gesture")
                return
        }
        guard audioController.state != .stopped else {
            // There is no audio sound playing - prepare to start playing for given audio message
            audioController.playSound(for: message, in: cell)
            return
        }
        if audioController.playingMessage?.messageId == message.messageId {
            // tap occur in the current cell that is playing audio sound
            if audioController.state == .playing {
                audioController.pauseSound(for: message, in: cell)
            } else {
                audioController.resumeSound()
            }
        } else {
            // tap occur in a difference cell that the one is currently playing sound. First stop currently playing and start the sound for given message
            audioController.stopAnyOngoingPlaying()
            audioController.playSound(for: message, in: cell)
        }
    }
}

//MARK: - message layout

extension ChatViewController: MessagesLayoutDelegate {
    
    public func cellBottomLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        
        return 12
    }
    
    public func cellTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 3
    }
}


//MARK: - Message Download/Upload delegate

extension ChatViewController: MultiemdiaProgressDelegate{
    
    //MARK: - multimedia datasource
    
    public func multimediaProgress(_ messageCollectionView: MessagesCollectionView,
                                   taskProgressCount indexPath: IndexPath) -> Double? {
        
        let currentMessage = self.mockMessages[indexPath.section]
        return currentMessage.payload.taskProgress?.fractionCompleted
    }
    
    
    public func multimediaProgress(_ messageCollectionView: MessagesCollectionView,
                                   multimediaType indexPath: IndexPath) -> MultimediaProgressType {
        
        let payload = self.mockMessages[indexPath.section].payload
        return payload.isDownloadType() ? .download : .upload
    }
    
    
    public func multimediaProgress(_ messageCollectionView: MessagesCollectionView,
                                   initOperation indexPath: IndexPath) -> Bool {
        
        let payload = self.mockMessages[indexPath.section].payload
        return !payload.operationFailed && payload.taskProgress == nil
    }
    
    public func multimediaProgress(_ messageCollectionView: MessagesCollectionView, canRetry indexPath: IndexPath) -> Bool {
        
        let payload = self.mockMessages[indexPath.section].payload
        return payload.operationFailed
    }
    
    
    
    public func multimediaProgress(_ messageCollectionView: MessagesCollectionView,
                                   update indexPath: IndexPath,
                                   with type: MultimediaProgressType,
                                   taskProgressNotification: @escaping () -> Void) {
        
        let currentMessage = self.mockMessages[indexPath.section]
        self.mockMessages[indexPath.section].payload.operationFailed = false

        switch type {

        case .upload:

            guard let localImageURL = currentMessage.payload.localResource else{
                return
            }

            let storage = self.chatManager.storage

            storage.uploadFile(userId:currentMessage.payload.userId,
                               filePath: localImageURL,
                               progress: { (progressCount) in

                self.mockMessages[indexPath.section].payload.taskProgress = progressCount
                taskProgressNotification()

            }) { (url) in

                guard let safeUrl  = url else{

                    // upload failed //
                    self.mockMessages[indexPath.section].payload.operationFailed = true

                    DispatchQueue.main.async {
                        messageCollectionView.reloadItems(at: [indexPath])
                    }

                    return
                }

                self.sendMultimediaMessage(resourceURL: safeUrl.absoluteString,
                                           localURL: localImageURL,
                                           message: self.mockMessages[indexPath.section].payload)

            }

        case .download:

            currentMessage.payload.downloadMultimedia(progressHandler: { (progressCount) in

                self.mockMessages[indexPath.section].payload.taskProgress = progressCount
                taskProgressNotification()

            }) { (destinationURL) in

                if destinationURL == nil{

                    self.mockMessages[indexPath.section].payload.operationFailed = true
                    DispatchQueue.main.async {
                        messageCollectionView.reloadItems(at: [indexPath])
                    }
                    return
                }

                let newMessage = MessageKitModel(sender: currentMessage.sender,
                                                 payload: currentMessage.payload)

                self.addMessage(mediaItem: newMessage)

            }
        }
    }
    
    public func multimediaProgress(_ messageCollectionView: MessagesCollectionView,
                                   retryOperation indexPath: IndexPath) {
        
        self.mockMessages[indexPath.section].payload.operationFailed = false

        DispatchQueue.main.async {
            messageCollectionView.reloadItems(at: [indexPath])
        }
        
    }
    
}


//MARK: - message display Delegate

extension ChatViewController: MessagesDisplayDelegate{
    
    public func  avatarImageViewForAudioCell(_ imageView: UIImageView,
                                             for audioCell: AudioMessageCell,
                                             at indexPath: IndexPath,
                                             in messageCollectionView: MessagesCollectionView) {
        
        let avatarId = self.mockMessages[indexPath.section].sender.id
        let bundle = Bundle(for:ChatViewController.self)
        let placeholder = UIImage(named: "user2",
                                  in: bundle,
                                  compatibleWith: nil)
        
        imageView.image = placeholder
        
        channelManager.getAvatar(avatarId: avatarId) { (url) in
            
            guard let safeURL = url else{
                return
            }
            
            imageView.sd_setImage(with: safeURL, placeholderImage: placeholder)
        }
    }
    
    
    public func messageStyle(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
        
        if message.sender.id == self.sender.id{
            return MessageStyle.bubbleTail(.bottomRight, .pointedEdge)
        }
        
        return  MessageStyle.bubbleTail(.bottomLeft, .pointedEdge)
    }
    
    public func textColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        
        return  message.sender.id == self.currentSender().id ? .white : .black
    }
    
    public func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        
        let color: UIColor = message.sender.id == self.currentSender().id ? .senderColor : .receiverColor
        
        return color
    }
    
    //MARK: - audio cells
    
    public func audioTintColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return isFromCurrentSender(message: message) ? .white : UIColor(red: 15/255, green: 135/255, blue: 255/255, alpha: 1.0)
    }
    
    public func configureAudioCell(_ cell: AudioMessageCell, message: MessageType) {
        audioController.configureAudioCell(cell, message: message) // this is needed especily when the cell is reconfigure while is playing sound
    }
    
    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {

//        let distance = (self.mockMessages.count - 1) - indexPath.section
//
//        if distance > 0 {
//
//            let indexPath = IndexPath(item: 0, section: distance)
//
//            if let cell = collectionView.cellForItem(at: indexPath){
//
//                let visible = collectionView.visibleCells.contains(cell)
//
//                UIView.animate(withDuration: 0.25) {
//                    self.moreMessageIndicator.alpha = visible ? 1 : 0
//                }
//            }
//        }
    }
}

//MARK: - MessageInput bar Delegate

extension ChatViewController: MessageInputBarDelegate, WehpahInputBarHooksDelegate{
    
    public func messageInputBar(_ inputBar: MessageInputBar, didPressSendButtonWith text: String) {
        
        if !activeIssue{
            return
        }
        
        let idMessage = UUID.init().uuidString
        self.sendTextMessage(message: text, uuid: idMessage)
        inputBar.inputTextView.text = ""
    }
    
    
    public func messageInputBar(_ inputBar: MessageInputBar, textViewTextDidChangeTo text: String) {
        
        guard let bar  = inputBar as? WehpahMessageBar else{
            return
        }
        
        bar.updateSendButton()
    }
    
    public func messageInputBar(_ inputBar: MessageInputBar, multimediaButtonPressed button: InputBarButtonItem) {
        
        let alert = UIAlertController(title: nil,
                                      message: nil,
                                      preferredStyle: .actionSheet)
        
        let fileButton = UIAlertAction(title: "Files", style: .default) { (_) in
            
            let documentsTypes:[String] = [
                String(kUTTypePDF),
                String(kUTTypePlainText),
                "public.text",
                "com.apple.iwork.pages.pages",
                "public.data"
            ]

            let documentPicker = UIDocumentPickerViewController(documentTypes:documentsTypes, in: .import)
            documentPicker.delegate = self

            let navigationVC = UINavigationController(rootViewController: documentPicker)
            let backButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(self.closeDocumentPicker))
            documentPicker.navigationItem.rightBarButtonItem = backButton
            self.present(navigationVC, animated: true, completion: nil)
        }
        
        let galleryButton = UIAlertAction(title: "Gallery", style: .default) { (_) in
            
            let picker = UIImagePickerController()
            picker.delegate = self
            self.present(picker, animated: true)
            self.scrollBottomWithNotification()
            
        }
        
        let cameraButton = UIAlertAction(title: "Camera", style: .default) { (_) in
            
            let imagePicker =  UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = .camera
            self.present(imagePicker, animated: true, completion: nil)
            self.scrollBottomWithNotification()
            
        }
        
        let cancelButton = UIAlertAction(title: "Cancel", style: .cancel) { (_) in
            self.scrollBottomWithNotification()
        }
        
        alert.addAction(fileButton)
        alert.addAction(galleryButton)
        alert.addAction(cameraButton)
        alert.addAction(cancelButton)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    
    public func messageInputBar(_ inputBar: WehpahMessageBar, recordingButtonLongPressed longPress: UILongPressGestureRecognizer) {
        
        switch longPress.state {
        case .began:
            
            if !isRecordingAudio{
                self.startRecording()
            }
        case .cancelled:
            self.finishRecording(success: false)
            
        case .ended:
            self.finishRecording(success: true,with: inputBar.recordingDuration)
        default:
            break
        }
    }
    
    func audioPermissons(){
        
        recordingSession = AVAudioSession.sharedInstance()
        
        do {
            try recordingSession.setCategory(AVAudioSessionCategoryPlayAndRecord)
            try recordingSession.setActive(true)
            recordingSession.requestRecordPermission() { [unowned self] allowed in
                DispatchQueue.main.async {
                    if allowed {
                        self.canSendAudio = true
                    }
                }
            }
        } catch {
            // failed to record missing permisonss!
            
            let alert = UIAlertController(title: "Error",
                                          message: "Habilite los permisos para utilizar el micrófono",
                                          preferredStyle:  .alert)
            let doneAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
            alert.addAction(doneAction)
            
            DispatchQueue.main.async {
                self.present(alert, animated: true)
            }
        }
    }
    
    //MARK: - Audio helpers
    
    func startRecording() {
        
        self.isRecordingAudio = true
        
        if !activeIssue{
            return
        }
        
        let audioName = "\(UUID.init().uuidString).m4a"
        self.audioFileName = getDocumentsDirectory().appendingPathComponent(audioName)
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: self.audioFileName, settings: settings)
            audioRecorder.delegate = self
            audioRecorder.record()
            
        } catch {
            finishRecording(success: false)
        }
    }
    
    
    func finishRecording(success: Bool, with duration: TimeInterval = 0) {
        
        defer{
            audioRecorder = nil
        }
        
        self.isRecordingAudio = false
        
        let recordingValidate = success && duration > TimeInterval(1)
        
        
        if audioRecorder != nil{
            audioRecorder.stop()
        }
        
        if recordingValidate {
            self.uploadMultimediaFile(url: self.audioFileName, type: .audio)
        }
    }
    
    //MARK: file helpers
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
}

//MARK: - Audio Recorder delegate
extension ChatViewController: AVAudioRecorderDelegate{
    
    public func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder,
                                                successfully flag: Bool) {
        if !flag {
            finishRecording(success: false)
        }
    }
}

//MARK: - Picker Delegate

extension ChatViewController:  UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    
    
    public func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        
        navigationController.navigationBar.isTranslucent = true
        let backgroundImage = UIImage.imageWithColor(color: UIColor.principalAppColor)
        navigationController.navigationBar.setBackgroundImage(backgroundImage, for: .default)
        let textAttributes = [NSAttributedStringKey.foregroundColor:UIColor.white]
        navigationController.navigationBar.titleTextAttributes = textAttributes
        navigationController.navigationBar.barTintColor = .white
    }
    
    
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        
        dismiss(animated: false)
        let image = info[UIImagePickerControllerOriginalImage] as! UIImage
        self.editPhoto(image: image)
        
    }
    
    //MARK: - HELPERS
    
    private func editPhoto(image: UIImage){
        
        let photoEditor = PhotoEditorViewController(nibName:"PhotoEditorViewController",bundle: Bundle(for: PhotoEditorViewController.self))
        
        photoEditor.photoEditorDelegate = self
        
        let bundle = Bundle(for:ChatViewController.self)
        
        photoEditor.stickers = [
            UIImage(named: "wehpah", in: bundle, compatibleWith: nil)!,
            UIImage(named: "wehpahLogo", in: bundle, compatibleWith: nil)!,
            UIImage(named: "wPlaceHolder", in: bundle, compatibleWith: nil)!
        ]
        
        photoEditor.colors = [.principalAppColor,.pinkApp,.cyanChat,.black,.white]
        photoEditor.image = image
        photoEditor.hiddenControls = [.crop]
        self.present(photoEditor, animated: true)
        
    }

}

//MARK: - Implement Eventus Photo Editor Delegate

extension ChatViewController: PhotoEditorDelegate{
    
    public func doneEditing(image: UIImage) {
        
        let url = self.saveImage(image: image)
        
        guard let safeUrl = url else{
            return
        }
        
        self.uploadMultimediaFile(url: safeUrl,type: .image)
    }
    
    public func canceledEditing() {
        
    }
   
}

//MARK: - UIDocument Picker Delegate
extension ChatViewController: UIDocumentPickerDelegate {
    
    
    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        
        do{
            let data = try Data.init(contentsOf: url)
            let mimeType = self.mimeType(for: data)
            self.uploadMultimediaFileWith(mimeType: mimeType, url: url, type: .file)
        }catch{
            self.uploadMultimediaFile(url: url, type: .file)
        }
        
    }
    
    @objc func closeDocumentPicker(){
        self.dismiss(animated: true, completion:nil)
    }
    
    //MARK: - helper
}

//extension ChatViewController: RateChatCellDelegate {
//    
//    func sendRateButtonTapped(numberOfStar:Int, comments:String) {
//        
//        self.view.endEditing(true)
//        
//        let keyIssue = self.channel.key
//        let clientComments = comments
//        let rateStars = numberOfStar
//        
//        self.channelManager.setRoomRating(keyIssue: keyIssue, rateStars: rateStars, rateComments: clientComments)
//        
//        self.startAnimating()
//        Task.rateAnIssue(keyIssue: keyIssue, rateStars: rateStars, clientComments: clientComments) { (response) in
//            self.stopAnimating()
//            
//            switch response {
//            case .success(let data):
//                print("\(data)")
//            case .error(let stringError):
//                let alert = UIAlertController(title: "Error", message: stringError, preferredStyle: .alert)
//                let action = UIAlertAction(title: "OK", style: .cancel)
//                alert.addAction(action)
//                self.present(alert, animated: true, completion: nil)
//            }
//        }
//    }
//}


