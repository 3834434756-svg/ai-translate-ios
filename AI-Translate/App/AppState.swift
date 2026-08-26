import SwiftUI

/// 应用共享状态容器：统一持有各个管理器，并构造字幕桥接器。
@MainActor
final class AppState: ObservableObject {
    static let shared = AppState()

    let speechManager: SpeechManager
    let translationService: TranslationService
    let floatingWindow: FloatingWindowManager
    let bridge: SubtitleBridge

    private init() {
        let sm = SpeechManager()
        let ts = TranslationService()
        let fw = FloatingWindowManager()
        speechManager = sm
        translationService = ts
        floatingWindow = fw
        bridge = SubtitleBridge(floatingWindow: fw, translationService: ts)
    }
}