//
//  ChatViewControllerExtension.swift
//  CoreChat
//
//  Created by Juan  Vasquez on 2/13/19.
//  Copyright © 2019 com.anincubator. All rights reserved.
//

import Foundation
import Common

extension ChatViewController: UIDocumentInteractionControllerDelegate {
    /// If presenting atop a navigation stack, provide the navigation controller in order to animate in a manner consistent with the rest of the platform
    public func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController{
        
        guard let tab = self.tabBarController else {
            return self
        }
        return tab
    }
}


extension ChatViewController {
    /// This function will set all the required properties, and then provide a preview for the document
    func share(url: URL,name:String) {
        documentInteractionController.url = url
        documentInteractionController.uti = url.typeIdentifier ?? "public.data, public.content"
        documentInteractionController.name = name
        documentInteractionController.presentPreview(animated: true)
    }
    
    /// This function will store your document to some temporary URL and then provide sharing, copying, printing, saving options to the user
    func storeAndShare(withURLString: String,title:String) {
        guard let url = URL(string: withURLString) else { return }
        /// START YOUR ACTIVITY INDICATOR HERE
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else { return }
            let tmpURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(response?.suggestedFilename ?? "fileName.png")
            do {
                try data.write(to: tmpURL)
            } catch {
                print(error)
            }
            DispatchQueue.main.async {
                /// STOP YOUR ACTIVITY INDICATOR HERE
                self.share(url: tmpURL, name: title)
            }
            }.resume()
    }
    
    func mimeType(for data: Data) -> String {
        
        var b: UInt8 = 0
        data.copyBytes(to: &b, count: 1)
        
        switch b {
        case 0xFF:
            return "image/jpeg"
        case 0x89:
            return "image/png"
        case 0x47:
            return "image/gif"
        case 0x4D, 0x49:
            return "image/tiff"
        case 0x25:
            return "application/pdf"
        case 0xD0:
            return "application/vnd"
        case 0x46:
            return "text/plain"
        default:
            return "application/octet-stream"
        }
    }
    
    
    func saveImage(image:UIImage) -> URL?{
        
        let docDir = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)

        let filePath = docDir.appendingPathComponent(UUID.init().uuidString + ".jpeg");

        do{

            if let jpgImageData = image.jpeg(.low){
                try jpgImageData.write(to : filePath , options : .atomic)
                return filePath
            }

        }catch{
            print("couldn't write image")
            return nil

        }
        
        return nil
    }

}

