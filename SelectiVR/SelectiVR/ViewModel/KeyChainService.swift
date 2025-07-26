//
//  KeyChainService.swift
//  SelectiVR
//
//  Created by byeoungjik on 7/18/25.
//  Copyright © 2025 Apple. All rights reserved.
//

import Foundation
import Security

// 키체인에 데이터를 안전하게 저장하고 관리하는 유틸리티 클래스입니다.
class KeychainService {
    
    // 이 서비스는 인스턴스를 만들 필요 없이 바로 사용할 수 있도록 static으로 만듭니다.
    static let shared = KeychainService()
    private init() {} // 다른 곳에서 실수로 인스턴스를 또 만드는 것을 방지합니다.

    // 키체인에 저장할 때 사용할 고유한 서비스 이름과 계정 이름입니다.
    private let service = "com.HoodieLovers.SelectiVR" // 앱의 번들 ID 등을 사용하는 것이 좋습니다.
    private let account = "user_access_token"

    // MARK: - 토큰 저장
    func save(token: String) {
        // 토큰 문자열을 데이터 형태로 변환합니다.
        guard let data = token.data(using: .utf8) else { return }
        
        // 1. 키체인 쿼리를 정의합니다.
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        // 2. 먼저 기존에 저장된 값이 있는지 확인하고 삭제합니다. (업데이트를 위해)
        SecItemDelete(query as CFDictionary)
        
        // 3. 새로운 값을 저장하기 위한 쿼리를 만듭니다.
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data
        ]
        
        // 4. 키체인에 새로운 토큰을 추가합니다.
        let status = SecItemAdd(addQuery as CFDictionary, nil)
        
        if status == errSecSuccess {
            print("✅ 키체인에 토큰이 성공적으로 저장되었습니다.")
        } else {
            print("🛑 키체인 저장 오류: \(status)")
        }
    }

    // MARK: - 토큰 읽기
    func retrieveToken() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecSuccess {
            if let retrievedData = dataTypeRef as? Data,
               let token = String(data: retrievedData, encoding: .utf8) {
                print("✅ 키체인에서 토큰을 성공적으로 읽어왔습니다.")
                return token
            }
        }
        print("ℹ️ 키체인에 저장된 토큰이 없습니다.")
        return nil
    }

    // MARK: - 토큰 삭제
    func deleteToken() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        if status == errSecSuccess {
            print("✅ 키체인에서 토큰이 성공적으로 삭제되었습니다.")
        }
    }
}
