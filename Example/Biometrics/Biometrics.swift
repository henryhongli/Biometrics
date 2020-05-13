//
//  Biometrics.swift
//  Biometrics_Example
//
//  Created by 洪利 on 2020/5/13.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import Foundation

import LocalAuthentication

/// 生物识别
open class Biometrics {
    
    /// Style: 生物识别类型
    /// - none: 无生物识别
    /// - face_Id: 面部识别
    /// - touch_Id: 指纹识别
    public enum Style: CustomStringConvertible {
        case none, face_Id, touch_Id
        
        public var description: String {
            switch self {
            case .none: return ""
            case .face_Id: return "面容ID"
            case .touch_Id: return "触控ID"
            }
        }
    }
    
    private let policy: LAPolicy
        
    /// 最新的指纹识别
    /// - Parameter policy: 策略
    public init(policy: LAPolicy = .deviceOwnerAuthenticationWithBiometrics) {
        self.policy = policy
    }
    
    /// 系统支持的识别方式
    public let system: Style = Biometrics.systemSupportBiometrics
    
    /// Apple系统设置内文案
    public var systemDescription: String {
        switch system {
        case .none: return ""
        case .face_Id, .touch_Id:
            return "系统设置 -> \(system.description)\("与密码")"
        }
    }
    
    /// 此机器是否有生物识别
    public var isSet: Bool { return system != .none }
    
    
    public static func analysis(_ error: Error?) -> Result<(), Wrong> {
        
        guard let e = error as? LAError else { return .success(()) }

        let code = Int32(e.code.rawValue)
        
        switch code {
        /// 认证被取消了，因为用户点击回退按钮
        case kLAErrorUserFallback: return .failure(.fallback)
        /// 身份验证被用户取消（当用户点击取消按钮时提示）
        case kLAErrorUserCancel: return .failure(.cancelByUser)
        /// 身份验证被系统取消（验证时当前APP被移至后台或者点击了home键导致验证退出时提示
        case kLAErrorSystemCancel: return .failure(.cancel)
        /// 身份验证没有成功，因为用户未能提供有效的凭据(连续3次验证失败时提示)
        case kLAErrorAuthenticationFailed: return .failure(.wrong)
        case kLAErrorBiometryNotEnrolled, kLAErrorTouchIDNotEnrolled:
            return .failure(.notEnrolled)
        case kLAErrorBiometryNotAvailable, kLAErrorTouchIDNotAvailable:
            return .failure(.notAvailable)
        case kLAErrorBiometryLockout, kLAErrorTouchIDLockout:
            return .failure(.lockout)
        default: return .failure(.wrong)
        }

    }
    
    static var appName: String {
        if let info = Bundle.main.infoDictionary, let name = info["CFBundleDisplayName"] as? String {
            return name
        }
        return ""
    }
    
    /// 生物识别解锁
    ///
    /// - Parameters:
    ///   - reason: 解锁原因
    ///   - tryUnlock: 识别结果
    
    public static func tryUnlock(_ reason: String = "--", _ tryUnlock: @escaping (Result<(), Wrong>) -> Void) {
                
        
        LAContext().evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: (reason == "--" ? "解锁\(Biometrics.appName)":reason)) { (success, error) in
        
            DispatchQueue.main.async {
                
                if success {
                    tryUnlock(.success(()))
                }
                else {
                    tryUnlock(analysis(error))
                }

            }
            
        }

    }
    
    
    public enum Wrong: Error {
        case cancel, cancelByUser, notAvailable, wrong, lockout, notEnrolled, fallback
    }

}


extension Biometrics: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        let e = enable_lockout
        return "style: \(system), enable: \(e.enable), lockout: \(e.lockout), enrolled: \(e.enrolled)"
    }
    
}

extension Biometrics {
    
    
    /// 是否 可用/被锁定
    public var enable_lockout: (enable: Bool, lockout: Bool, enrolled: Bool) {
        
        var error: NSError?
        
        let enable = LAContext().canEvaluatePolicy(policy, error: &error)
        
        var lock = false
        
        var enrolled = true
        
        let analysis = Biometrics.analysis(error)
        
        /// 如果被锁定
        if case .failure(.lockout) = analysis {
            lock.toggle()
        }
        
        /// 如果未设置
        if case .failure(.notEnrolled) = analysis {
            enrolled.toggle()
        }
        
        return (enable && !lock && enrolled, lock, enrolled)
    }
    
    
    
    /// 系统支持的识别方式
    private static let systemSupportBiometrics: Biometrics.Style = {
        /// 如果是模拟器
        if isSimulator() { return .none }
        
        var sysinfo = utsname()
        uname(&sysinfo)
        guard let str = String(bytes: Data(bytes: &sysinfo.machine, count: Int(_SYS_NAMELEN)), encoding: .ascii) else { return .none }
        let deviceString = str.trimmingCharacters(in: .controlCharacters)
        let array = deviceString.components(separatedBy: ",")
        
        guard let deviceName = array.first else { return .none }
        
        if !deviceName.hasPrefix("iPhone") { return .none }
        
        guard let era = Int(deviceName.replacingOccurrences(of: "iPhone", with: "")) else { return .none }
        
        if era > 10 || (deviceString == "iPhone10,3") || (deviceString == "iPhone10,6") {
            return .face_Id
        }
        else if (era >= 6 && era <= 10) {
            return .touch_Id
        }
        else {
            return .none
        }
    }()
    
    
    static func isSimulator() -> Bool {
        if let _ = ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] { return true }
        return false
    }
}

