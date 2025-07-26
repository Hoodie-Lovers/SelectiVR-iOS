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
    
    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .black // 탭 바의 배경색을 검은색으로 지정
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
    var body: some View {
        TabView {
            PrimaryView()
                .tabItem {
                    Label("메인", systemImage: "camera.fill")
                }
                .environment(AppDataModel.instance)
            
            SettingsView()
                .tabItem {
                    Label("설정", systemImage: "gear")
                }
        }
        .tint(.white)
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

