//
//  Downloader.swift
//  CoreChat
//
//  Created by Juan  Vasquez on 2/13/19.
//  Copyright © 2019 com.anincubator. All rights reserved.
//

import Foundation
import Alamofire

public class Downloader{
    
    public class func downloadFile(to:URL,
                                   save inDirectory:URL,
                                   progressHandler:@escaping(_ progress: Progress) ->Void,
                                   completion:@escaping(_ url: URL?) ->Void){
        
        
        let destination: DownloadRequest.DownloadFileDestination = { _, _ in
            return (inDirectory, [.removePreviousFile, .createIntermediateDirectories])
        }
        
        Alamofire.download(
            to,
            method: .get,
            parameters: nil,
            encoding: JSONEncoding.default,
            headers: nil,
            to: destination).downloadProgress(closure: { (progress) in
                progressHandler(progress)
            }).response(completionHandler: { (DefaultDownloadResponse) in
                //here you able to access the DefaultDownloadResponse
                //result closure
                guard let destinationURL = DefaultDownloadResponse.destinationURL else{
                    completion(nil)
                    return
                }
                completion(destinationURL)
            })
    }
}
