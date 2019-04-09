//
//  ChannelView.swift
//  ChatUI
//
//  Created by Juan  Vasquez on 2/8/19.
//  Copyright © 2019 com.anincubator. All rights reserved.
//

import Foundation
import MessageKit
import Common

public class ChannelView: UIView, UITableViewDelegate, BaseViewProtocol{
    

     public var parentController: UIViewController
    
    //MARK: - UI Vars
     var tableView: UITableView!
     var newChannelButton: UIButton!
     let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
    
    private var reuseIdentifier = "ChannelCellIndentifier"
    
    
    required public init(_ parentController: UIViewController) {
        self.parentController = parentController
        super.init(frame: parentController.view.frame)
        self.parentController.view = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func setupView() {
        
        // add tableView //
        tableView = UITableView(frame: .zero, style: .plain)
        self.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        tableView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        tableView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        
        // set badge color for tap //
        self.parentController.tabBarItem?.badgeColor = UIColor.principalAppColor

        // set search bar //
        //TODO: Implement search Bar view
//        let searchController = UISearchController(searchResultsController: nil)
//
//        if let controller = parentController as? UISearchResultsUpdating{
//            searchController.searchResultsUpdater = controller
//        }
        
//        searchController.obscuresBackgroundDuringPresentation = false
//        searchController.searchBar.placeholder = "Search"
//        searchController.searchBar.backgroundColor = UIColor.white
//        backgroundColor = .white
//        parentController.navigationItem.searchController = searchController
//        parentController.definesPresentationContext = true
        
        newChannelButton = UIButton()
        newChannelButton.setTitle("+", for: .normal)
        newChannelButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 30)
        newChannelButton.setTitleColor(.white, for: .normal)
        
        self.addSubview(newChannelButton)
        newChannelButton.translatesAutoresizingMaskIntoConstraints = false
        newChannelButton.trailingAnchor.constraint(equalTo: trailingAnchor,constant:-15).isActive = true
        newChannelButton.bottomAnchor.constraint(equalTo: bottomAnchor,constant:-20).isActive = true
        newChannelButton.widthAnchor.constraint(equalToConstant: 60).isActive = true
        newChannelButton.heightAnchor.constraint(equalToConstant: 60).isActive = true
        
        self.addSubview(activityIndicator)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        activityIndicator.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        
        self.tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 60, right: 0)
        parentController.navigationItem.title = "Customer Support"
        
        // new channel button style //
        self.newChannelButton.layer.cornerRadius = 30
        self.newChannelButton.layer.masksToBounds = false
        newChannelButton.backgroundColor = UIColor.principalAppColor
        newChannelButton.layer.shadowColor = UIColor.darkGray.cgColor
        newChannelButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        newChannelButton.layer.shadowRadius = 1
        newChannelButton.layer.shadowOpacity = 0.5
       
        // configure refresh control //
        self.tableView.addSubview(activityIndicator)
        self.activityIndicator.hidesWhenStopped = true
        self.activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        self.activityIndicator.centerXAnchor.constraint(equalTo: tableView.centerXAnchor).isActive = true
        self.activityIndicator.centerYAnchor.constraint(equalTo: tableView.centerYAnchor).isActive = true
        
        // back button style //
        let backItem = UIBarButtonItem()
        parentController.navigationItem.backBarButtonItem = backItem
        self.tableView.tableFooterView = UIView()
        
        // setup cells
        self.setupCell()
    }
    
    private func setupCell(){
        tableView.register(ChannelCell.self, forCellReuseIdentifier: self.reuseIdentifier)
    }
    
    func configureCell(tableView:UITableView) -> ChannelCell{
        
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) as! ChannelCell
        return cell
    }
    
}
