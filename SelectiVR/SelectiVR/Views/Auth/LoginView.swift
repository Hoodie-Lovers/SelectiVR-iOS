//
//  LoginView.swift
//  SelectiVR
//
//  Created by byeoungjik on 7/16/25.
//  Copyright © 2025 Apple. All rights reserved.
//

import SwiftUI
import GoogleSignIn
import GoogleSignInSwift

struct LoginView: View {
    
    @EnvironmentObject var authService: GoogleAuthService
    
    // [개선] 로딩 및 에러 상태를 관리하기 위한 @State 변수 추가
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var isShowingAlert = false

    var body: some View {
        ZStack {
            
            VStack(spacing: 20) {
                Spacer()
                
                Text("SelectiVR")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .padding(.bottom, 40)
                
                // [개선] 로딩 상태에 따라 UI를 분기합니다.
                if isLoading {
                    // --- 로딩 중 UI ---
                    ProgressView("로그인 중...")
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.5)
                } else {
                    // --- 기본 UI ---
                    // 로그인 상태는 ContentView에서 관리하므로, 여기서는 로그인 버튼만 보여줍니다.
                    // (로그인 성공 시 ContentView가 알아서 메인 화면으로 전환할 것입니다.)
                    
                    // GoogleSignInSwift에서 제공하는 공식 로그인 버튼
                    GoogleSignInButton(viewModel: GoogleSignInButtonViewModel(scheme: .dark, style: .wide, state: .normal)) {
                        // [개선] 비동기 작업을 처리하고 에러를 핸들링하기 위해 Task를 사용합니다.
                        handleSignIn()
                    }
                    .padding(.horizontal, 30)
                }
                
                Spacer()
            }
            .padding()
        }
        // [개선] 에러 메시지가 있을 경우 Alert을 표시합니다.
        .alert("로그인 실패", isPresented: $isShowingAlert, presenting: errorMessage) { _ in
            Button("확인") {
                errorMessage = nil
            }
        } message: { message in
            Text(message)
        }
    }
    
    /// 로그인 버튼을 눌렀을 때 호출되는 함수
    private func handleSignIn() {
        Task {
            // 1. 로딩 상태 시작
            isLoading = true
            
            do {
                // 2. GoogleAuthService의 signIn 함수를 호출합니다.
                // 이 함수 내부에서 NetworkService.shared.loginWithGoogle이 호출될 것입니다.
                try await authService.signIn()
                
                // 로그인이 성공하면 authService.isLoggedIn이 true로 바뀌고,
                // ContentView에서 화면 전환이 일어나므로 여기서는 로딩 상태만 해제합니다.
                // (만약 전환이 즉시 일어나지 않는다면 여기서 isLoading = false를 호출할 수 있습니다.)
                
            } catch let error as NetworkError {
                // 3. NetworkService에서 정의한 구체적인 에러를 처리합니다.
                switch error {
                case .badURL:
                    errorMessage = "서버 주소가 올바르지 않습니다."
                case .serverError(let statusCode, let message):
                    errorMessage = "서버 에러가 발생했습니다 (코드: \(statusCode)).\n메시지: \(message ?? "없음")"
                case .decodingError:
                    errorMessage = "서버 응답을 처리하는데 실패했습니다."
                case .requestFailed:
                    errorMessage = "네트워크 연결을 확인해주세요."
                default:
                    errorMessage = "알 수 없는 에러가 발생했습니다: \(error.localizedDescription)"
                }
                isShowingAlert = true
                
            } catch {
                // 4. 그 외 Google 로그인 자체의 에러 등을 처리합니다.
                errorMessage = "로그인 과정에서 예기치 않은 오류가 발생했습니다: \(error.localizedDescription)"
                isShowingAlert = true
            }
            
            // 5. 작업 완료 후 로딩 상태 종료
            isLoading = false
        }
    }
}
