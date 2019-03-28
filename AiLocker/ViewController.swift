//
//  ViewController.swift
//  AiLocker
//
//  Created by sekiya on 2019/03/18.
//  Copyright © 2019 sekiya. All rights reserved.
//

import UIKit
import SVGKit
import AVFoundation

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    @IBOutlet weak var settingButton: UIButton!
    @IBOutlet weak var previewView: UIView!
    @IBOutlet weak var detectionLabel: UILabel!
    
    // カメラからの入出力データをまとめるセッション
    var session: AVCaptureSession!
    // プレビューレイヤ
    var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    
    var cimageCTR = CapturedImageController.init()
    
    var counter: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // 環境変数をセット
        loadEnv()
        
        // settingButtonに"setting_icon.svg"を適応
        createSettingButton()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // カメラをセットアップ
        initCamera()
        
        // モデルを初期化
        cimageCTR.loadModel()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Viewが閉じられたとき、セッションを終了
        self.session.stopRunning()
        // メモリ解放
        for output in self.session.outputs {
            self.session.removeOutput(output as AVCaptureOutput)
        }
        for input in self.session.inputs {
            self.session.removeInput(input as AVCaptureInput)
        }
        self.session = nil
    }
    
    // 環境変数をセット
    func loadEnv() {
        let env = ProcessInfo.processInfo.environment
        saveKeyChain(key: "URL", value: env["SERVER_URL"]!)
        print(getKeyChain(key: "URL") ?? "failed")
    }
    
    // settingButtonに"setting_icon.svg"を適応
    func createSettingButton() {
        let settingSVG = SVGKImage(named: "setting_icon.svg")
        settingSVG?.size = settingButton.bounds.size
        settingButton.setImage(settingSVG?.uiImage, for: .normal)
    }
    
    // カメラをセットアップ
    private func initCamera() {
        // バックカメラを取得
        guard let caputureDevice = AVCaptureDevice.default(for: AVMediaType.video)
            else {
                print("バックカメラにアクセスできません")
                return
        }
        
        do {
            // 入力設定
            let input = try AVCaptureDeviceInput(device: caputureDevice)
            // 出力設定
            let output: AVCaptureVideoDataOutput = AVCaptureVideoDataOutput()
            // 出力設定: カラーチャンネル
            output.videoSettings = [kCVPixelBufferPixelFormatTypeKey : kCVPixelFormatType_32BGRA] as [String : Any]
            // 出力設定: デリゲート、画像をキャプチャするキュー
            output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
            // 出力設定: キューがブロックされているときに新しいフレームが来たら削除
            output.alwaysDiscardsLateVideoFrames = true
            
            // セッションの作成
            self.session = AVCaptureSession()
            // 解像度を設定
            self.session.sessionPreset = .medium
            
            // セッションに追加.
            if self.session.canAddInput(input) && self.session.canAddOutput(output) {
                self.session.addInput(input)
                self.session.addOutput(output)
                
                // プレビュー開始
                self.startPreview()
            }
        }
        catch _ {
            print("error occurd")
        }
    }
    // カメラ入力をプレビュー
    private func startPreview() {
        // 画像を表示するレイヤーを生成
        self.videoPreviewLayer = AVCaptureVideoPreviewLayer(session: self.session)
        // カメラ入力の縦横比を維持したまま、レイヤーいっぱいに表示
        self.videoPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        // 縦向きで固定
        self.videoPreviewLayer.connection?.videoOrientation = .portrait
        
        // previewViewに追加
        self.previewView.layer.addSublayer(videoPreviewLayer)
        
        // startRunningメソッドはブロッキングメソッドなので、非同期に並列処理を行う
        // qos引数は処理の優先順位
        DispatchQueue.global(qos: .userInitiated).async {
            // セッション開始
            self.session.startRunning()
            // 上記処理の終了後、下記処理をメインスレッドで実行
            DispatchQueue.main.async {
                // プレビュー開始
                self.videoPreviewLayer.frame = self.previewView.bounds
            }
        }
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
                // Todo: URLの最後のスラッシュを消す処理
                // Todo: https://をつける処理
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
    
    // =========================================================================
    // delegate method
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
//        １秒に2回実行
        if counter % 15 == 0 {
            //        アラートはメインスレッドで出す
            DispatchQueue.main.sync {
                // 物体検出
                let guessResult = cimageCTR.abc((CMSampleBufferGetImageBuffer(sampleBuffer) as! CVPixelBuffer))
                
                // デバッグ用
                detectionLabel.text = guessResult
                
                
                if(guessResult == "computer keyboard") {
                    // もし、検出結果が"computer keyboard"だったら、ロックする
                    aiLockerController(alertTitle: "ロックしますか", requestPath: "/lock/")
                } else if(guessResult == "pencil box") {
                    
                    // もし、検出結果が"Pencil Box"だったら、ロックを解除する
                    aiLockerController(alertTitle: "ロックしますか", requestPath: "/unlock/")
                } else {
                    // それ以外なら、何もしない
                }
            }
        }
        counter += 1
    }
    
    func aiLockerController(alertTitle: String, requestPath: String) {
        // アラートのインスタンス
        let alert = UIAlertController(title:alertTitle, message: "", preferredStyle: .alert)
        // 登録ボタン
        let action1 = UIAlertAction(title: "はい", style: UIAlertAction.Style.default, handler: { Void in
            // 通信先のURLを生成
            let url:NSURL = NSURL(string:getKeyChain(key: "URL")! + requestPath)!
            
            // リクエストを生成
            let request:NSURLRequest  = NSURLRequest(url: url as URL)
            
            // 同期通信を開始
            do {
                try NSURLConnection.sendSynchronousRequest(request as URLRequest, returning: nil)
            } catch {
                print(error)
            }
        })
        // キャンセルボタン
        let cancel = UIAlertAction(title: "キャンセル", style: UIAlertAction.Style.cancel, handler: nil)
        
        alert.addAction(action1)
        alert.addAction(cancel)
        
        self.present(alert, animated: true, completion: nil)
    }
    
}
