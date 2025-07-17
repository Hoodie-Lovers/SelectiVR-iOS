// GoogleSignInService.swift

import Foundation
import GoogleSignIn

// SwiftUI 뷰에서 로그인 상태를 감지할 수 있도록 ObservableObject 채택
class GoogleAuthService: ObservableObject {
    
    // @Published를 사용하여 로그인 상태가 변경되면 뷰가 자동으로 업데이트되도록 함
    @Published var user: GIDGoogleUser?
    
    init() {
        // 앱 시작 시 이전에 로그인한 사용자가 있는지 확인
        GIDSignIn.sharedInstance.restorePreviousSignIn { [weak self] user, error in
            if let error = error {
                print("Error restoring previous sign-in: \(error.localizedDescription)")
                return
            }
            
            // 이전 로그인 정보가 있다면 user 속성에 할당
            self?.user = user
        }
    }
    
    /// Google 로그인 프로세스를 시작하는 함수
    func signIn() {
        // 현재 화면의 최상단 뷰 컨트롤러를 가져옴
        guard let presentingViewController = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.rootViewController else {
            print("Error: Could not find root view controller.")
            return
        }
        
        // Google 로그인 UI를 표시
        GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController) { [weak self] signInResult, error in
            if let error = error {
                print("Error signing in: \(error.localizedDescription)")
                return
            }
            
            // 로그인 성공 시 user 속성에 결과 할당
            guard let result = signInResult else { return }
            self?.user = result.user
            print("✅ Sign-in successful! User: \(result.user.profile?.name ?? "N/A")")
        }
    }
    
    /// 로그아웃 함수
    func signOut() {
        GIDSignIn.sharedInstance.signOut()
        // user 속성을 nil로 변경하여 뷰를 업데이트
        self.user = nil
        print("Log out successful.")
    }
}
