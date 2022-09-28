//
//  UserDefaults.swift
//  Preview
//
//  Created by zhouziyuan on 2022/9/21.
//

import Foundation

extension UserDefaults {
    
    enum DefaultType:String {
        case Provision
        
        var name:String {
            return "User_Save_\(self.rawValue)_Key"
        }
    }
    
    static let share = UserDefaults(suiteName: "com.yingguqing.preview")
    
    func load(key:DefaultType) -> Any? {
        return value(forKey: key.name)
    }
    
    func save(key:DefaultType, value:Any) {
        setValue(value, forKey: key.name)
    }
}
