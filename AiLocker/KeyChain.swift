//
//  KeyChain.swift
//  AiLocker
//
//  Created by sekiya on 2019/03/20.
//  Copyright © 2019 sekiya. All rights reserved.
//

import Foundation
// 保存
func saveKeyChain(key: String, value: String) {
//    utf-8でエンコード
    let data = value.data(using: .utf8)
//    空文字だった場合のバリデーション
    guard let _data = data else {
        return
    }
//    key-valueのディクショナリを作る
    let dic: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                              kSecAttrGeneric as String: key,
                              kSecValueData as String: _data]
    
//    値を追加した際の結果
    var itemAddStatus: OSStatus?
    // 保存データが存在するかを確認
    let matchingStatus = SecItemCopyMatching(dic as CFDictionary, nil)
    if matchingStatus == errSecItemNotFound {
        // 保存
        itemAddStatus = SecItemAdd(dic as CFDictionary, nil)
    } else if matchingStatus == errSecSuccess {
        // 更新
        itemAddStatus = SecItemUpdate(dic as CFDictionary, [kSecValueData as String: _data] as CFDictionary)
    } else {
        print("保存失敗")
    }
    // 保存・更新ステータス確認
    if itemAddStatus == errSecSuccess {
        print("正常終了")
    } else {
        print("保存失敗")
    }
}

// 取得
func getKeyChain(key: String) -> String? {
    //    keyからvalueを取得するためのディクショナリ
    let dic: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                              kSecAttrGeneric as String: key,
                              kSecReturnData as String: kCFBooleanTrue]
//    結果保存用の変数
    var data: AnyObject?
//    検索
    let matchingStatus = withUnsafeMutablePointer(to: &data){
        SecItemCopyMatching(dic as CFDictionary, UnsafeMutablePointer($0))
    }
    
    if matchingStatus == errSecSuccess {
        print("取得成功")
        if let getData = data as? Data,
            let getStr = String(data: getData, encoding: .utf8) {
            return getStr
        }
        print("取得失敗: Dataが不正")
        return nil
    } else {
        print("取得失敗")
        return nil
    }
}
