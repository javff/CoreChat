//
//  BaseView.swift
//  ChatUI
//
//  Created by Juan  Vasquez on 2/8/19.
//  Copyright © 2019 com.anincubator. All rights reserved.
//

import Foundation
import UIKit


public protocol BaseViewProtocol: class{
    
    var parentController: UIViewController {get set}
    func setupView()
    init(_ parentController: UIViewController)
}



public class BaseView<T:BaseViewProtocol>: UIViewController{
    
    var baseView:T!
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        self.baseView = T.init(self)
        baseView.setupView()
    }
    
    
    
}
