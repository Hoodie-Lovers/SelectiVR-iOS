/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The single entry point of the app.
*/

import SwiftUI

@main
struct SelectiVRApp: App {
    static let subsystem: String = "com.example.apple-samplecode.guided-capture-sample"

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(AppDataModel.instance)
        }
    }
}
