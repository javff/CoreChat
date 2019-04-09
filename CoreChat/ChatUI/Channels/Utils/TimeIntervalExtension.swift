//
//  TimeIntervalExtension.swift
//  ChatUI
//
//  Created by Juan  Vasquez on 2/8/19.
//  Copyright © 2019 com.anincubator. All rights reserved.
//

import Foundation

extension Double{
    
    public func getPrettyPrice() -> String{
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        formatter.locale = Locale(identifier: "en_US")
        formatter.currencyDecimalSeparator = "."
        formatter.currencyGroupingSeparator = ","
        formatter.currencySymbol = "$"
        let result = formatter.string(from: self as NSNumber)
        return result!
    }
}


extension TimeInterval{
    
     public func getDistanceOfTimeInPrettyFormat() -> String{
        
        let convertTimestamp = self / 1000
        let date = Date(timeIntervalSince1970: convertTimestamp)
        let calendar = Calendar.current.dateComponents([.month,.day,.hour,.minute], from: date, to: Date())
        var prettyDate = ""
        
        if calendar.month != nil && calendar.month! > 0{
            
            let termination = calendar.month! == 1 ? "month ago" : "months ago"
            prettyDate += "\(calendar.month!) \(termination)"
            return prettyDate
            
        }
        
        if calendar.day != nil && calendar.day! > 0{
            
            let termination = calendar.day! == 1 ? "day ago" : "days ago"
            prettyDate += "\(calendar.day!) \(termination)"
            return prettyDate
            
        }
        
        
        if calendar.hour != nil && calendar.hour! > 0 && calendar.month == nil{
            
            let termination = calendar.hour! == 1 ? "hour ago" : "hours ago"
            prettyDate += "\(calendar.hour!) \(termination)"
            return prettyDate
            
        }
        
        if calendar.minute != nil && calendar.minute! > 0{
            
            let termination = calendar.minute! == 1 ? "minute ago" : "minutes ago"
            prettyDate += "\(calendar.minute!) \(termination)"
            return prettyDate
            
        }
        
        if prettyDate.isEmpty{
            prettyDate += "moments ago"
        }
        
        return prettyDate
    }

}
