// GoogleAuthService.swift

import Foundation
import GoogleSignIn
import UIKit // topViewController 헬퍼를 위해 필요합니다.

// [개선] @MainActor를 사용하여 모든 메서드와 프로퍼티 접근이 메인 스레드에서 실행되도록 보장합니다.
// 이렇게 하면 UI 업데이트 시 DispatchQueue.main.async를 수동으로 호출할 필요가 없습니다.
@MainActor
class GoogleAuthService: ObservableObject {
    
    @Published var isLoggedIn: Bool = false
    
    private let keychainService = KeychainService.shared
    private let networkService = NetworkService.shared

    init() {
        // 앱 시작 시 키체인에 토큰이 있는지 확인하여 로그인 상태를 초기화합니다.
        // 이 로직은 동기적으로 실행되어도 괜찮습니다.
        if keychainService.retrieveToken() != nil {
            self.isLoggedIn = true
            print("✅ 기존 로그인 정보를 발견하여 로그인 상태로 시작합니다.")
        }
    }
    
    /// [개선] Google 로그인 및 서버 인증을 비동기(async)로 처리하고, 오류를 반환(throws)하도록 변경합니다.
    func signIn() async throws {
        // 1. 최상단 뷰 컨트롤러 찾기
        guard let topViewController = topViewController() else {
            // [개선] LoginView에서 처리할 수 있도록 구체적인 에러를 던집니다.
            throw NetworkError.unknown(message: "로그인 UI를 표시할 최상위 뷰를 찾을 수 없습니다.")
        }
        
        // 2. [개선] Google 로그인 UI를 표시하고 결과를 비동기적으로 기다립니다.
        // completion handler 대신 async/await를 사용합니다.
        let signInResult: GIDSignInResult
        do {
            signInResult = try await GIDSignIn.sharedInstance.signIn(withPresenting: topViewController)
        } catch {
            // Google 로그인 자체가 취소되거나 실패한 경우
            print("🛑 Google 로그인 오류: \(error.localizedDescription)")
            throw error // 받은 에러를 그대로 다시 던져서 LoginView에서 처리하도록 합니다.
        }
        
        // 3. Google ID 토큰 가져오기
        guard let idToken = signInResult.user.idToken?.tokenString else {
            print("🛑 오류: Google ID Token을 가져올 수 없습니다.")
            throw NetworkError.unknown(message: "Google ID Token을 가져오는 데 실패했습니다.")
        }
        
        print("✅ Google 인증 성공. 이제 우리 서버에 로그인을 요청합니다...")
        
        // 4. [개선] 서버에 로그인 요청 (try가 자동으로 에러를 전파합니다)
        // do-catch 블록이 필요 없습니다. 에러가 발생하면 이 함수를 호출한 곳(LoginView)으로 전파됩니다.
        let ourAccessToken = try await networkService.loginWithGoogle(idToken: idToken)
        
        // 5. [개선] 성공 시 토큰을 저장하고 로그인 상태를 업데이트합니다.
        // @MainActor 덕분에 DispatchQueue.main.async를 사용할 필요가 없습니다.
        keychainService.save(token: ourAccessToken)
        self.isLoggedIn = true
        print("✅ 서버 로그인 성공! 앱이 로그인 상태로 전환됩니다.")
    }
    
    /// 로그아웃 함수
    func signOut() {
        GIDSignIn.sharedInstance.signOut()
        keychainService.deleteToken()
        self.isLoggedIn = false
        print("로그아웃 되었습니다.")
    }
    
    // MARK: - Helper
    
    /// 현재 화면의 최상단 뷰 컨트롤러를 찾는 헬퍼 함수
    private func topViewController() -> UIViewController? {
        let keyWindow = UIApplication.shared.connectedScenes
            .filter { $0.activationState == .foregroundActive }
            .compactMap { $0 as? UIWindowScene }
            .first?.windows
            .filter { $0.isKeyWindow }
            .first
        
        var topController = keyWindow?.rootViewController
        while let presentedViewController = topController?.presentedViewController {
            topController = presentedViewController
        }
        return topController
    }
}

// NetworkService.swift에 정의된 NetworkError에 case를 추가하거나, 아래와 같이 별도 정의가 필요할 수 있습니다.
extension NetworkError {
    static func unknown(message: String) -> NetworkError {
        return .unknown(NSError(domain: "GoogleAuthService", code: 0, userInfo: [NSLocalizedDescriptionKey: message]))
    }
}
