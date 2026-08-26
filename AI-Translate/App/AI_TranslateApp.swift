import SwiftUI

@main
struct AI_TranslateApp: App {
    @StateObject private var speechManager = SpeechManager()
    @StateObject private var translationService = TranslationService()
    @StateObject private var floatingWindow = FloatingWindowManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(speechManager)
                .environmentObject(translationService)
                .environmentObject(floatingWindow)
                .onAppear {
                    speechManager.requestAuthorization()
                }
        }
    }
}
