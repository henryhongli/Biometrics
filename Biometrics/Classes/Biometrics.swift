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
        case none, face, touch
        
        public var description: String {
            switch self {
            case .none: return ""
            case .face: return "面容ID"
            case .touch: return "触控ID"
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
        case .face, .touch:
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
    ///   - policy: 策略, deviceOwnerAuthentication 支持当多次验证错误后, 点击手动输入密码可以唤起设备密码输入页面
    ///   - reason: 解锁原因
    ///   - tryUnlock: 识别结果
    
    public static func tryUnlock(_ policy: LAPolicy = .deviceOwnerAuthenticationWithBiometrics, _ reason: String = "--", _ tryUnlock: @escaping (Result<(), Wrong>) -> Void) {
                
        var option = policy
        if #available(iOS 9.0, *), policy == .deviceOwnerAuthentication {
            option = .deviceOwnerAuthentication
        } else {
            if policy != .deviceOwnerAuthenticationWithBiometrics {
                print("Biometrics :----   您的设备系统版本过低, 不支持  deviceOwnerAuthentication 策略, 已为您调整为  deviceOwnerAuthenticationWithBiometrics  ----")
            }
            option = .deviceOwnerAuthenticationWithBiometrics
        }
        LAContext().evaluatePolicy(option, localizedReason: (reason == "--" ? "解锁\(Biometrics.appName)":reason)) { (success, error) in
            DispatchQueue.main.async {
                
                if success {
                    tryUnlock(.success(()))
                } else {
                    tryUnlock(analysis(error))
                }
            }
        }
    }
    
    public enum Wrong: Error {
        case cancel, cancelByUser, notAvailable, wrong, lockout, notEnrolled, fallback
        public var descriotion: String {
            switch self {
            case .cancel:return "取消"
            case .cancelByUser:return "用户点击取消"
            case .notAvailable:return "设备不支持"
            case .wrong:return "身份验证没有成功，因为用户未能提供有效的凭据(连续3次验证失败时提示)"
            case .lockout:return "Touch ID 功能被锁定"
            case .notEnrolled:return "Touch ID没有注册的手指"
            case .fallback:return "用户点击输入密码"
                
            }
        }
    }

}

extension Biometrics: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        let e = enableLockout
        return "style: \(system), enable: \(e.enable), lockout: \(e.lockout), enrolled: \(e.enrolled)"
    }
    
}

public struct BIOLockOut {
    let enable: Bool
    let lockout: Bool
    let enrolled: Bool
}

extension Biometrics {
    
    /// 是否 可用/被锁定
    public var enableLockout: BIOLockOut {
        
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
        return BIOLockOut(enable: enable && !lock && enrolled, lockout: lock, enrolled: enrolled)
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
        
        if isFaceStyle(deviceString: deviceName, era: era) == true { return .face }
        if ( era >= 6 && era <= 10 ) == true { return .touch }
        return .none
        
    }()
    
    private static func isFaceStyle (deviceString: String, era: Int) -> Bool {
        return (era > 10 || (deviceString == "iPhone10,3") || (deviceString == "iPhone10,6"))
    }
    static func isSimulator() -> Bool {
        guard ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] != nil else {
            return true
        }
        return false
    }
}
