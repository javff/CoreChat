//
//  PushNotificationHandler.swift
//  CoreChat
//
//  Created by Juan  Vasquez on 2/18/19.
//  Copyright © 2019 com.anincubator. All rights reserved.
//

import Foundation
import Common
import UserNotifications
import Firebase


open class ChatNotificationHandler{
    
    public class func registerPushNotification(notificationDelegate:UNUserNotificationCenterDelegate,
                                               application: UIApplication,
                                               didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?){
        

        UNUserNotificationCenter.current().delegate = notificationDelegate
        
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        
        UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { (_, error) in
            guard error == nil else{
                print(error!.localizedDescription)
                return
            }
        }
        
        
        //get application instance ID
        InstanceID.instanceID().instanceID { (result, error) in
            if let error = error {
                print("Error fetching remote instance ID: \(error)")
            } else if let result = result {
                print("Remote instance ID token: \(result.token)")
            }
        }
        
        application.registerForRemoteNotifications()
        
        
    }
    
    public class func handlerBackgroundNotification(didReceive response: UNNotificationResponse,
                                                    withCompletionHandler completionHandler: @escaping (_ channel: ChannelModelProtocol) -> Void){
        
        let userInfo = response.notification.request.content.userInfo

        guard let title = userInfo["title"] as? String else{
            return
        }

        guard let userId = userInfo["userId"] as? String else{
            return
        }
        
        guard let channelId = userInfo["channelId"] as? String else{
            return
        }
        
        
        let channel = ChannelModel(channelName: title,
                                   lastUpdateTimestamp:0,
                                   participantId: userId)
        
        channel.key = channelId
        
        completionHandler(channel)
        
    }
    
    public class func handlerForegroundNotification(willPresent notification: UNNotification,
                                                    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void){
        
        
        guard let vc = UIApplication.topViewController() else{
            return
        }
        

        if vc is ChatViewController{
            return
        }
        
        completionHandler([.sound,.badge])
        
        
    }
    
    
    public class func handlerRemoteNotification(coreSettings:CoreChatSettings,
                                                didReceiveRemoteNotification userInfo:[AnyHashable : Any],
                                                fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void){
        
        guard let title = userInfo["title"] as? String else{
            return
        }
        guard let body = userInfo["body"] as? String else{
            return
        }
        
        guard let channelId = userInfo["channelId"] as? String else{
            return
        }
        
        
        if let type = userInfo["type"] as? String,
            type == "channel"{
            
            ChatNotificationHandler.scheduleNotification(at: Date(),
                                                         body: body,
                                                         title: title,
                                                         channelId:channelId,
                                                         userInfo: userInfo)
            completionHandler(.newData)
            return
        }
        
        
        
        
        guard let userId = userInfo["userId"] as? String else{
            return
        }

        guard let messageKey = userInfo["uuid"] as? String else{
            return
        }

        let channel = ChannelModel(channelName: title,
                                   lastUpdateTimestamp:0,
                                   participantId: userId)
        
        
        let chatManager = ChatManager(userUid: userId,
                                      channel: channel,
                                      chatSettings: coreSettings)
        
        chatManager.markMessageAsReceived(messageKey: messageKey)
        
        ChatNotificationHandler.scheduleNotification(at: Date(),
                                                     body: body,
                                                     title: title,
                                                     channelId:channelId,
                                                     userInfo: userInfo)
        
        completionHandler(.newData)
        
    }
    
    
    private class func scheduleNotification(at date: Date,
                                           body: String,
                                           title:String,
                                           channelId:String,
                                           userInfo:[AnyHashable:Any]) {
        
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval:1.0, repeats: false)
        let content = UNMutableNotificationContent()
        let id = UUID.init().uuidString
        content.title = title
        content.body = body
        content.userInfo = userInfo
        content.sound = UNNotificationSound.default()
        content.threadIdentifier = channelId
        
        let request = UNNotificationRequest(identifier: id,
                                            content: content,
                                            trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) {(error) in
            if let error = error {
                print("Uh oh! We had an error: \(error)")
            }
            print("send success")
        }
    }
}
