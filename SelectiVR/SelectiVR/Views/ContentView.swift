/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The top-level app view.
*/

import SwiftUI
import os

private let logger = Logger(subsystem: SelectiVRApp.subsystem, category: "ContentView")

struct ContentView: View {
    
    @EnvironmentObject private var authService: GoogleAuthService

    var body: some View {
        TabView {
            PrimaryView()
                .tabItem {
                    Label("메인", systemImage: "ark.fill")
                }
                .environment(AppDataModel.instance)
            
            // [추가] 로그아웃 버튼을 포함한 설정 탭
            SettingsView()
                .tabItem {
                    Label("설정", systemImage: "gear")
                }
        }
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
            logger.log("ContentView appeared. Idle timer disabled.")
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
            logger.log("ContentView disappeared. Idle timer enabled.")
        }
    }
}

// [추가] 설정 뷰와 로그아웃 기능 예시
struct SettingsView: View {
    @EnvironmentObject private var authService: GoogleAuthService
    
    var body: some View {
        VStack(spacing: 20) {
            Text("설정")
                .font(.largeTitle)
            
            Button(action: {
                authService.signOut()
            }) {
                Text("로그아웃")
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            
            Spacer()
        }
    }
}

