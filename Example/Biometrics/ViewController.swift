//
//  ViewController.swift
//  Biometrics
//
//  Created by 261930323@qq.com on 05/13/2020.
//  Copyright (c) 2020 261930323@qq.com. All rights reserved.
//

import UIKit
import Biometrics
class ViewController: UIViewController {

    @IBOutlet weak var bioResult: UILabel!
    private var canStillTry: Bool = true
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    @IBAction func startBio(_ sender: Any) {
        Biometrics.tryUnlock(.deviceOwnerAuthentication, "识别失败") { [weak self] (result) in
            switch result {
            case .failure(let error):
                self?.bioResult.text = error.descriotion
                switch error {
                case .fallback:
                    print("用户点击取消/或deviceOwnerAuthenticationWithBiometrics模式下选择输入密码")
                    return
                default:
                    guard let `self` = self else { return }
                    if self.canStillTry {
                        self.canStillTry.toggle()
                    }
                }
            case .success:
                self?.bioResult.text = "验证成功"
            }
            
        }
//        Biometrics.tryUnlock { [weak self] (result) in
//            switch result {
//            case .failure(let error):
//                self?.bioResult.text = error.descriotion
//                switch error {
//                case .fallback:
//
//                    return
//                default:
//                    guard let `self` = self else { return }
//                    if self.canStillTry {
//                        self.canStillTry.toggle()
//                    }
//                }
//            case .success:
//                self?.bioResult.text = "验证成功"
//            }
//
//        }
    }
    
}

