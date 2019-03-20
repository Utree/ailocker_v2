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
        // 設定ボタンをセット
        let settingSVG = SVGKImage(named: "setting_icon.svg")
        settingSVG?.size = settingButton.bounds.size
        settingButton.setImage(settingSVG?.uiImage, for: .normal)
    }

    @IBAction func onClickSettingButton(_ sender: Any) {
        // アラートのインスタンス
        let alert = UIAlertController(title:"URLを変更", message: "", preferredStyle: .alert)
        // アラートにテキストフィールドを追加
        alert.addTextField { textField in
            textField.placeholder = "https://www.example.com"
        }
        // 登録ボタン
        let action1 = UIAlertAction(title: "登録", style: UIAlertAction.Style.default, handler: { Void in
            if let url = alert.textFields?.first?.text {
                saveKeyChain(key: "URL", value: url)
                print(getKeyChain(key: "URL") ?? "failed")
            }
        })
        // キャンセルボタン
        let cancel = UIAlertAction(title: "キャンセル", style: UIAlertAction.Style.cancel, handler: nil)
        
        alert.addAction(action1)
        alert.addAction(cancel)
        
        self.present(alert, animated: true, completion: nil)
    }
    
}

