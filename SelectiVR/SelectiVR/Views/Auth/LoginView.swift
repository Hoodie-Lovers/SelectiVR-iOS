//
//  Login.swift
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
    
    var body: some View {
        ZStack {
            
            VStack(spacing: 20) {
                Spacer()
                
                Text("SelectiVR")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .padding(.bottom, 40)
                
                // 로그인 상태에 따라 다른 뷰를 표시
                if let user = authService.user {
                    // --- 로그인 후 UI ---
                    VStack(spacing: 15) {
                        Text("환영합니다, \(user.profile?.name ?? "사용자")님!")
                            .font(.headline)
                        
                        Button("로그아웃") {
                            authService.signOut()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                    }
                    
                } else {
                    // --- 로그인 전 UI ---
                    
                    // GoogleSignInSwift에서 제공하는 공식 로그인 버튼
                    GoogleSignInButton(viewModel: GoogleSignInButtonViewModel(scheme: .dark, style: .wide, state: .normal)) {
                        // 버튼을 누르면 signIn 함수 호출
                        authService.signIn()
                    }
                    .padding(.horizontal, 30) // 버튼 좌우 여백
                    .frame(height: 48) // 버튼 높이 지정
                }
                
                Spacer()
                Spacer() // 로고와 버튼을 위쪽으로 더 밀어 올리기 위해 Spacer 추가
            }
            .padding()
        }
    }
}
