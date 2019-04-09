//
//  SecurityOauth.swift
//  ChatServices
//
//  Created by wehpah on 1/27/19.
//  Copyright © 2019 Educate. All rights reserved.
//

import Foundation
import FirebaseAuth
import GoogleSignIn

public class FirebaseLogin{
    
    public class func registerIntoFirebase(email:String, password:String){
        
        Auth.auth().createUser(withEmail: email, password: password) { (authResult, error) in
            guard let user = authResult?.user else { return }
            print("Register into firebase: \(user.email ?? "")")
        }
    }
    
    public  class func registerIntoFirebaseWithGoogle(idToken:String, accessToken:String){
        
        let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
        
        Auth.auth().signInAndRetrieveData(with: credential) { (result, error) in
            
            if  error != nil{return}
            
            print("Register into firebase with google: \(result?.additionalUserInfo?.username ?? "")")
        }
    }
}
