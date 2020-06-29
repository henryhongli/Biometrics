# Biometrics

[![CI Status](https://img.shields.io/travis/261930323@qq.com/Biometrics.svg?style=flat)](https://travis-ci.org/261930323@qq.com/Biometrics)
[![Version](https://img.shields.io/cocoapods/v/Biometrics.svg?style=flat)](https://cocoapods.org/pods/Biometrics)
[![License](https://img.shields.io/cocoapods/l/Biometrics.svg?style=flat)](https://cocoapods.org/pods/Biometrics)
[![Platform](https://img.shields.io/cocoapods/p/Biometrics.svg?style=flat)](https://cocoapods.org/pods/Biometrics)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements
![类图](https://raw.githubusercontent.com/henryhongli/Biometrics/master/Example/iOS%20生物识别.png)
## Installation

Biometrics is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:




```ruby
pod 'Biometrics'
```
or
```ruby
pod 'Biometrics', :git => 'https://github.com/henryhongli/Biometrics.git'
```
or
```ruby
pod 'Biometrics', :git => 'https://github.com/henryhongli/Biometrics.git',, :tag => '0.1.0'
```

## Author

261930323@qq.com, zhang_mao008@163.com

## License

Biometrics is available under the MIT license. See the LICENSE file for more info.


# How to use

## <font color=ff4848>Step 1</font>
### Set property to the <font color=5494ff>Info.plist</font>
```ruby
key:  "Privacy - Face ID Usage Description"
value: "使用FaceID解锁$(BUNDLE_DISPLAY_NAME)"

```


## <font color=ff4848>Step 2</font>
```ruby
import Biometrics
```
then

start localAuthentication with func 

```ruby
/// 生物识别解锁
///
/// - Parameters:
///   - policy: 策略, 
              .deviceOwnerAuthentication 支持当多次验证错误后, 点击手动输入密码可以唤起设备密码输入页面
              .deviceOwnerAuthenticationWithBiometrics 多次失败后 点击手动输入密码只会取消弹窗, 不唤起密码输入
///   - reason: 解锁原因
///   - tryUnlock: 识别结果
public static func tryUnlock(_ policy: LAPolicy = .deviceOwnerAuthenticationWithBiometrics, _ reason: String = "--", _ tryUnlock: @escaping (Result<(), Wrong>) -> Void) {}

```


```ruby
Biometrics.tryUnlock(.deviceOwnerAuthentication, "解锁App") { [weak self] (result) in
            switch result {
            case .failure(let error): return
                print(error.descriotion)
                switch error {
                case .fallback:
                    print("用户点击取消/或deviceOwnerAuthenticationWithBiometrics模式下选择输入密码")
                    break
                default: break
                }
            case .success: return
                print("验证成功")
            }
        }

```
