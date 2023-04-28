//
//  APIConstant.swift
//  BaseProject
//
//  Created by ipagong on 22/11/2019.
//  Copyright © 2019 ipagong. All rights reserved.
//

import Foundation
import UIKit

extension API {
    public struct Constant {
         public static var hidepath:Bool = true
    }
}

extension API.Constant {
    public struct Property {
        public static var bundleName:String        { return Bundle.main.infoDictionary!["CFBundleDisplayName"] as! String }
        public static var bundleVersion:String     { return Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String }
        public static var bundleIdentifier:String  { return Bundle.main.bundleIdentifier! }
        public static var deviceVersion:String     { return UIDevice.current.systemVersion }
        public static var deviceSimpleModel:String { return UIDevice.current.model }
        public static var machineName:String       { return Property.getMachineName() }
        public static var versionCode:Int          { return getVersionCode() }
        public static var deviceIdentifier:String  { return UIDevice.current.uuidString }
    }
}

extension API.Constant.Property {
    public struct UserDefined {
        public static var serviceDomain:String {
            return Bundle.main.infoDictionary!["SERVICE_DOMAIN"] as! String
        }
    }
}

extension API.Constant.Property {
    public struct Header {
        public static var userAgent: String  { return "\(bundleName)/\(bundleVersion)(\(versionCode)) iOS/\(deviceVersion)/\(machineName)" }
        public static var deviceInfo: String { return "\(deviceIdentifier) \(deviceSimpleModel.replacingOccurrences(of: " ", with: "_"))" }
        public static var language: String   { return Locale.preferredLanguages.first ?? defualtLanguage }
        public static var timeZone: String   { return TimeZone.current.identifier }
        public static var defualtLanguage = "ko-KR"
    }
}

fileprivate var gMachineName:String = ""

extension API.Constant.Property {
    
    fileprivate static func getMachineName() -> String {
        guard gMachineName.isEmpty else { return gMachineName }
        
        gMachineName = "UNKNWON"
        
        var sysinfo = utsname()
        
        uname(&sysinfo)
        
        guard let name:String = NSString(bytes: &sysinfo.machine,
                                         length: Int(_SYS_NAMELEN),
                                         encoding: String.Encoding.ascii.rawValue) as String? else { return gMachineName }
        
        gMachineName = name.components(separatedBy: ",").first ?? "UNKNOWN"
        
        if gMachineName.contains("i386") || gMachineName.contains("x86_64") { gMachineName = "iOS Simulator" }
        
        return gMachineName
    }
}

extension API.Constant.Property {
    
    fileprivate static func getVersionCode() -> Int {
        let verArr = bundleVersion.components(separatedBy: ".")
        let verConvertArr = verArr.enumerated().map{ (index, element) -> (Int) in
            let pos = Int(verArr.count - index - 1)
            let powValue = NSDecimalNumber(decimal: pow(100,pos))
            return ( Int(element)! * powValue.intValue )
        }
        return verConvertArr.reduce(0, +)
    }

}

fileprivate extension UIDevice {
    var isSimulator: Bool {
        var isSim = false
        #if arch(i386) || arch(x86_64)
        isSim = true
        #endif
        return isSim
    }

    var uuidString: String {
        if UIDevice().isSimulator {
            return "Simulator-0000-0000-0000-000000000000"
        } else {
            return identifierForVendor?.uuidString ?? "00000000-0000-0000-0000-000000000000"
        }
    }
}
