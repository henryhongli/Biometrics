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
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    @IBAction func startBio(_ sender: Any) {
        Biometrics.tryUnlock { [weak self] (result) in
            switch result {
            case .failure(let error):
                switch error {
                case .fallback:
                    bioResult.text = error.
                    return
                default:
                    guard let `self` = self else { return }
                    if self.canStillTry {
                        Showing("验证失败，请重试")
                        self.canStillTry.toggle()
                    }
                    else {
                        Showing("验证失败")
                        self.changeAccout()
                    }
                }
                
                
            case .success:
                self?.action.apply().start()
                
            }
            
        }
    }
    
}

