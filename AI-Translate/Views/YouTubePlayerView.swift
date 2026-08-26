import SwiftUI
import WebKit

/// 油管播放网页：贴链接/直接看，支持账号登录（cookie 持久化），
/// 通过注入 JS 读取字幕轨(CC)并实时翻译叠加。
struct YouTubePlayerView: UIViewRepresentable {
    @ObservedObject var bridge: SubtitleBridge
    var homeURL: URL

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        // 持久化数据存储，账号登录状态跨启动保留
        config.websiteDataStore = WKWebsiteDataStore.default()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []

        let contentController = WKUserContentController()
        contentController.addUserScript(SubtitleBridge.injectedScript())
        contentController.add(context.coordinator, name: SubtitleBridgeNames.scriptHandler)
        config.userContentController = contentController

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.isOpaque = false
        webView.backgroundColor = .black
        webView.allowsBackForwardNavigationGestures = true
        webView.load(URLRequest(url: homeURL))
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    static func dismantleUIView(_ uiView: WKWebView, coordinator: Coordinator) {
        uiView.configuration.userContentController.removeScriptMessageHandler(forName: SubtitleBridgeNames.scriptHandler)
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
        var parent: YouTubePlayerView

        init(_ parent: YouTubePlayerView) {
            self.parent = parent
        }

        nonisolated func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            parent.bridge.handleRawMessage(message.body as? [String: Any] ?? [:])
        }

        nonisolated func webView(_ webView: WKWebView,
                                 didFailProvisionalNavigation navigation: WKNavigation!,
                                 withError error: Error) {
            print("[WebView] 初始加载失败: \(error.localizedDescription)")
        }
    }
}