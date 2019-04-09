//
//  ChannelCell.swift
//  ChatUI
//
//  Created by Juan  Vasquez on 2/8/19.
//  Copyright © 2019 com.anincubator. All rights reserved.
//

import Foundation
import UIKit

class ChannelCell: UITableViewCell {
    
    var channelTitle: UILabel = {
        let label  = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 16)
        return label
    }()
    
    var previewLabel: UILabel = {
        
        let label  = UILabel()
        label.textColor = .darkGray
        label.font = UIFont.systemFont(ofSize: 13)
        return label
    }()
    
    var newMessageIndicator: UIView = {
        return UIView()
    }()
    
    var newMessageIndicatorLabel: UILabel = {
        
        let label = UILabel()
        label.numberOfLines = 2
        label.textColor = .white
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 12)
        return label
    }()
    
    
    var lastDate: UILabel = {
        let label = UILabel()
        label.numberOfLines = 2
        label.textColor = .darkGray
        label.textAlignment = .right
        label.font = UIFont.systemFont(ofSize: 12)
        return label
    }()
    
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    private func setupView(){
        
        // add channel title //
        contentView.addSubview(channelTitle)
        channelTitle.translatesAutoresizingMaskIntoConstraints = false
        channelTitle.topAnchor.constraint(equalTo: contentView.topAnchor,constant:15).isActive = true
        channelTitle.leadingAnchor.constraint(equalTo: contentView.leadingAnchor,constant:15).isActive = true
        channelTitle.trailingAnchor.constraint(equalTo: contentView.trailingAnchor,constant:-120).isActive = true
        
        // add preview label //
        contentView.addSubview(previewLabel)
        previewLabel.translatesAutoresizingMaskIntoConstraints = false
        previewLabel.topAnchor.constraint(equalTo: channelTitle.bottomAnchor,constant:5).isActive = true
        previewLabel.leadingAnchor.constraint(equalTo: channelTitle.leadingAnchor,constant:5).isActive = true
        previewLabel.trailingAnchor.constraint(equalTo: channelTitle.trailingAnchor).isActive = true
        
        // add last date label //
        contentView.addSubview(lastDate)
        lastDate.translatesAutoresizingMaskIntoConstraints = false
        lastDate.topAnchor.constraint(equalTo: channelTitle.topAnchor).isActive = true
        lastDate.trailingAnchor.constraint(equalTo: contentView.trailingAnchor,constant:-10).isActive = true
        lastDate.leadingAnchor.constraint(equalTo: channelTitle.trailingAnchor,constant: 10).isActive = true
        
        // add new Message View //
        contentView.addSubview(newMessageIndicator)
        newMessageIndicator.translatesAutoresizingMaskIntoConstraints = false
        newMessageIndicator.topAnchor.constraint(equalTo: lastDate.bottomAnchor,constant:5).isActive = true
        newMessageIndicator.trailingAnchor.constraint(equalTo: lastDate.trailingAnchor,constant: -5).isActive = true
        newMessageIndicator.widthAnchor.constraint(equalToConstant: 20).isActive = true
        newMessageIndicator.heightAnchor.constraint(equalToConstant: 20).isActive = true

        // add new Message Indicator //
        newMessageIndicator.addSubview(newMessageIndicatorLabel)
        newMessageIndicatorLabel.translatesAutoresizingMaskIntoConstraints = false
        newMessageIndicatorLabel.centerYAnchor.constraint(equalTo: newMessageIndicator.centerYAnchor).isActive = true
        newMessageIndicatorLabel.centerXAnchor.constraint(equalTo: newMessageIndicator.centerXAnchor).isActive = true

        // new Message indicator style //
        self.newMessageIndicator.backgroundColor = UIColor.principalAppColor
        self.newMessageIndicator.layer.cornerRadius = 10

    }
    
}
