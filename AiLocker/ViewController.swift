//
//  ViewController.swift
//  AiLocker
//
//  Created by sekiya on 2019/03/18.
//  Copyright © 2019 sekiya. All rights reserved.
//

import UIKit
import SVGKit

class ViewController: UIViewController {
    @IBOutlet weak var settingButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let settingSVG = SVGKImage(named: "setting_icon.svg")
        settingSVG?.size = settingButton.bounds.size
        settingButton.setImage(settingSVG?.uiImage, for: .normal)
    }

    @IBAction func onClickSettingButton(_ sender: Any) {
        
    }
    
}

