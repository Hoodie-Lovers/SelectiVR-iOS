//
//  ModelUploadView.swift
//  SelectiVR
//
//  Created by byeoungjik on 7/18/25.
//  Copyright © 2025 Apple. All rights reserved.
//

import SwiftUI

struct ModelUploadView: View {
    
    let modelFile: URL
    
    @State private var uploadMessage = ""
    @State private var isUploading = false
    
    private let keychainService = KeychainService.shared

    var body: some View {
        VStack(spacing: 20) {
            if isUploading {
                ProgressView()
                Text("업로드 중...")
            }
            
            Button("3D 모델 업로드 테스트") {
                uploadModel()
            }
            .buttonStyle(.borderedProminent)
            .disabled(isUploading)
            
            Text(uploadMessage)
                .padding()
        }
    }
    
    func uploadModel() {
        isUploading = true
        uploadMessage = ""
        
        // 1. 키체인에서 우리 서버의 액세스 토큰을 가져옵니다.
        guard let token = keychainService.retrieveToken() else {
            uploadMessage = "오류: 로그인이 필요합니다."
            isUploading = false
            return
        }
        
        // 2. 업로드할 파일의 URL을 가져옵니다.
        // (실제 앱에서는 Object Capture 결과물의 URL을 사용해야 합니다.)
        let fileURL = self.modelFile
        
        // 3. NetworkService를 사용하여 파일을 업로드합니다.
        Task {
            do {
                let message = try await NetworkService.shared.uploadModel(fileURL: fileURL, token: token)
                // 성공 시 서버가 보낸 메시지를 표시합니다.
                uploadMessage = "✅ \(message)"
            } catch {
                // 실패 시 에러 메시지를 표시합니다.
                uploadMessage = "🛑 업로드 실패: \(error.localizedDescription)"
            }
            isUploading = false
        }
    }
}

