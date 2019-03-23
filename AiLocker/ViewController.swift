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
    
    // カメラからの入出力データをまとめるセッション
    var session: AVCaptureSession!
    // プレビューレイヤ
    var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    
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
        CapturedImageController.init().testMethod()
    }
    
}
