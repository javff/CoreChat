//
//  ChannelPresenter.swift
//  ChatUI
//
//  Created by Juan  Vasquez on 2/8/19.
//  Copyright © 2019 com.anincubator. All rights reserved.
//

import Foundation
import UIKit

public protocol ChannelViewControllerDelegate:class{
    func getParticipantForChannel(completion:@escaping(_ participantId:String?) -> Void)
}

public class ChannelViewController: BaseView<ChannelView>, UITableViewDataSource,UITableViewDelegate,UISearchResultsUpdating{
    
    var channels: [ChannelModelProtocol] = []
    let channelManager:ChannelManagerProtocol
    
    //datasource//
    
    public weak var delegate: ChannelViewControllerDelegate?
    
    /*** badge for new messages ***/
    public var newMessageCount: Int = 0{
        didSet{
            self.tabBarItem?.badgeValue = newMessageCount == 0 ? nil : "\(newMessageCount)"
        }
    }
    
    public init(channelManager:ChannelManagerProtocol) {
        self.channelManager = channelManager
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - life cycle
    override public func viewDidLoad() {
        super.viewDidLoad()
        self.baseView.tableView.dataSource = self
        self.baseView.tableView.delegate = self
        self.addButtonHandlers()
        self.observeChannels()
        
        // disable actions by type //
        self.disableActionByType(type: channelManager.type)
        
    }
    
    
    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.newMessageCount = 0
    }
    
    
    //MARK: - Add target methods
    
    func addButtonHandlers(){
        self.baseView.newChannelButton.addTarget(self,
                                                 action: #selector(self.newChannelButtonTapped),
                                                 for: .touchDown)
    }
    
    
    
    public func updateSearchResults(for searchController: UISearchController) {
        print(searchController.searchBar.text!)
        
    }
    
    //MARK: - Bind Functions
    
    private func bindView(cell:ChannelCell, model:ChannelModelProtocol){
        
        cell.channelTitle.text = model.channelName
        cell.previewLabel.text = ""

        if let lastMessage = model.lastMessage, let type = lastMessage.type{
            
            switch type {
            case .audio:
                cell.previewLabel.text = "new record"
            case .image:
                cell.previewLabel.text = "new image"
            case .text:
                cell.previewLabel.text = lastMessage.message
            default:
                cell.previewLabel.text = ""
            }
        }
        
        cell.newMessageIndicator.isHidden = (model.unreadMessageCount == 0)
        cell.newMessageIndicatorLabel.text = "\(model.unreadMessageCount)"
        cell.lastDate.text = "\(model.lastUpdateTimestamp.getDistanceOfTimeInPrettyFormat())"
    }
    
    //MARK: - Funcs
    
    public func registerPushToken(token:String){
        self.channelManager.registerPushToken(token: token)
    }
    
    public func changeUser(userId:String){
        
        self.channels = []
        
        self.channelManager.changeUser(newUserId: userId)

        // reload table View if needed //
        if let tableView = self.baseView?.tableView{
           
            DispatchQueue.main.async {
                tableView.reloadData()
            }
            
            self.observeChannels()
        }
    }
    
    public func markReceivedMessage(messageId:String){
        //self.channelManager.mark
    }
    
    @objc func newChannelButtonTapped(){
        
        let alert = UIAlertController(title: "New Question",
                                      message: "enter title of your question",
                                      preferredStyle: .alert)
        
        alert.addTextField(configurationHandler: nil)
        
        let action = UIAlertAction(title: "Ask", style: .default) { (_) in
            self.createChannel(nameOfChannel: alert.textFields!.first!.text!)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(action)
        alert.addAction(cancelAction)
        self.present(alert, animated: true)
    }
    
    func createChannel(nameOfChannel:String){
        
        if nameOfChannel.isEmpty{return}
        
        self.baseView.activityIndicator.startAnimating()
                
        self.delegate?.getParticipantForChannel(completion: { (participantId) in
            
            self.baseView.activityIndicator.stopAnimating()
            
            guard let id = participantId else{
                return
            }
            
            self.createChannelWith(plannerId: id, and: nameOfChannel)
            
        })
    }
    
     //MARK: - ObserversChannels

    private func observeChannels() {
        
        self.channelManager.observerChangesInChannels {[weak self] (channel) in
            
            guard let weakSelf = self else{
                return
            }
            
            let index = weakSelf.channels.index(where: { (iteratorChannel) -> Bool in
                return iteratorChannel.key == channel.key
            })!
            
            weakSelf.channels.remove(at: index)
            weakSelf.channels.insert(channel, at: 0)
            
            let at = IndexPath(row: index, section: 0)
            let to = IndexPath(row: 0, section: 0)
            
            DispatchQueue.main.async {
                weakSelf.baseView.tableView.moveRow(at: at, to: to)
                weakSelf.baseView.tableView.reloadRows(at: [to], with: .fade)
            }
        }
        
        baseView.activityIndicator.startAnimating()
        
        self.channelManager.channelCollectionIsEmpty {[weak self] (isEmpty) in
            
            guard let weakSelf = self else{
                return
            }
            
            weakSelf.baseView.activityIndicator.stopAnimating()
        }
        
        self.channelManager.observerNewChannels {[weak self] (channel) in
            
            guard let weakSelf = self else{
                return
            }
            
            weakSelf.channels.insert(channel, at: 0)
            
            DispatchQueue.main.async {
                weakSelf.baseView.tableView.reloadData()
            }
        }
    }
    
    //MARK: - Helpers
    private func disableActionByType(type:ChannelType){
        
        switch type {
        
        case .planner:
            
            self.baseView.newChannelButton.isHidden = true
            
        default:
            break
        }
    }
    
    private func createChannelWith(plannerId:String, and channelName:String){
        
        let channel = ChannelModel(channelName: channelName,
                                   lastUpdateTimestamp: Date().timeIntervalSince1970 * 1000,
                                   participantId:plannerId)
        
        
        let room = self.channelManager.createRoom(channelPayload: channel)
        
        let chatManager = ChatManager(userUid: channelManager.myUid,
                                      channel: room,
                                      chatSettings: channelManager.coreSettings)
        
        let chatViewController = ChatViewController(channel: room,
                                                    channelManager: channelManager,
                                                    chatManager: chatManager)
        
        self.navigationController?.pushViewController(chatViewController, animated: true)
        
    }
    
    //MARK: - Implement Binding TableView //
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.channels.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = self.baseView.configureCell(tableView: tableView)
        let channel = self.channels[indexPath.row]
        self.bindView(cell: cell, model: channel)
        return cell
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let channel = self.channels[indexPath.row]
        self.openChannel(channel: channel)
        
     
    }
    

    public func openChannel(channel: ChannelModelProtocol){
        
        let chatManager = ChatManager(userUid: channelManager.myUid,
                                      channel: channel,
                                      chatSettings: channelManager.coreSettings)
        
        let chatVC = ChatViewController(channel: channel,
                                        channelManager: channelManager,
                                        chatManager: chatManager)
        
        self.navigationController?.pushViewController(chatVC, animated: true)
        
    }
}
