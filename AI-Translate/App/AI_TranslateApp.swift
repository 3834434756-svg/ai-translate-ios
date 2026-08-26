import SwiftUI

@main
struct AI_TranslateApp: App {
    private let appState = AppState.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState.speechManager)
                .environmentObject(appState.translationService)
                .environmentObject(appState.floatingWindow)
                .environmentObject(appState.bridge)
                .onAppear {
                    appState.speechManager.requestAuthorization()
                }
                .preferredColorScheme(.dark)
        }
    }
}