//
//  StorageManager.swift
//  ChatServices
//
//  Created by Juan  Vasquez on 1/4/19.
//  Copyright © 2019 Educate. All rights reserved.
//

import Foundation
import FirebaseStorage


public class StorageManager: StorageManagerProtocol{
    
    //MARK: - vars
    
    let settings:CoreChatSettings
    fileprivate var storage = Storage.storage()
    fileprivate lazy var storageRef: StorageReference = storage.reference(forURL: self.settings.firebaseBucket)

    
    //MARK: - Inits
    
    public init(bucketSettings: CoreChatSettings){
        self.settings = bucketSettings
        self.storage.maxOperationRetryTime = 5
        self.storage.maxUploadRetryTime = 5
    }
    
    
    //MARK: - Funcs
    
     public func downloadFile(filePath: String,
                             completion:@escaping(_ url: URL?,_ error: Error?) ->Void){
        
        
        
        self.storageRef.child(filePath).downloadURL { (url, error) in
            completion(url,error)
        }
    }
    
    
    // Utilizado cuando se actualiza el avatar desde la informacion de perfil
    public func uploadFile(uid: String, filePath:URL,
                           completion:@escaping(_ downloadURL: URL?) -> Void){
        
        
        let firebasePath = "\(uid)/avatar.\(filePath.pathExtension)"

        let ref = self.storageRef.child(firebasePath) //filePath.lastPathComponent)
        
        ref.putFile(from: filePath, metadata: nil) { (metadata, error) in
            
            if error != nil {
                completion(nil)
                return
            }
            
            ref.downloadURL { (url, error) in
                guard let downloadURL = url else {
                    completion(nil)
                    return
                }
                completion(downloadURL)
                
            }
        }
    }
    
    // Utilizado cuando se envían imágenes, audios desde el chat
    public func uploadFile(userId: String,
                           filePath:URL,
                           progress:@escaping(Progress?) -> Void,
                           completion:@escaping(_ downloadURL: URL?) -> Void){
        
        let firebasePath = "\(userId)/multimedia/\(filePath.lastPathComponent)"
        
        let ref = self.storageRef.child(firebasePath)

        let uploadTask = ref.putFile(from: filePath, metadata: nil) { (metadata, error) in
            
            if error != nil {
                completion(nil)
                return
            }
            
            ref.downloadURL { (url, error) in
                guard let downloadURL = url else {
                    completion(nil)
                    return
                }
                completion(downloadURL)
            }
        }
        
        uploadTask.observe(.progress) { snapshot in
            progress(snapshot.progress)
        }
        
        uploadTask.observe(.failure) { (_) in
            completion(nil)
            uploadTask.removeAllObservers()

        }
        
        uploadTask.observe(.success) { (_) in
            uploadTask.removeAllObservers()
        }
        
    }
    
    @discardableResult public func saveLocalMultimedia(url: URL, with key:String) -> URL?{
        
        var destinationUrl: URL = FileManager.default.urls(for: .documentDirectory,
                                                           in: .userDomainMask).first!
        
        
        destinationUrl.appendPathComponent(key)
        
        do {
            try FileManager.default.copyItem(at: url, to: destinationUrl)
            return destinationUrl
            
        } catch (let writeError) {
            print(writeError)
            return nil
        }
    }

}
