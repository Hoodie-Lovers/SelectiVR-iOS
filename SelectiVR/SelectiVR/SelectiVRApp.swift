/*
 See the LICENSE.txt file for this sample’s licensing information.
 
 Abstract:
 The single entry point of the app.
 */

import SwiftUI
import GoogleSignIn

@main
struct SelectiVRApp: App {
    static let subsystem: String = "com.example.apple-samplecode.guided-capture-sample"
    @StateObject private var authService = GoogleAuthService()
    
    var body: some Scene {
        WindowGroup {
            Group {
                if authService.isLoggedIn {
                    ContentView()
                } else {
                    LoginView()
                }
            }
            .onOpenURL { url in
                GIDSignIn.sharedInstance.handle(url)
            }
            .environmentObject(authService)
        }
    }
}
