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
        // 使用类似 Safari 的 UA，保证油管正常渲染
        webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"
        context.coordinator.webView = webView
        webView.load(URLRequest(url: homeURL))
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        // 处理 reload 与 URL 跳转
        let coordinator = context.coordinator
        if let url = bridge.targetURL, url != coordinator.lastLoadedURL {
            coordinator.lastLoadedURL = url
            DispatchQueue.main.async {
                uiView.load(URLRequest(url: url))
            }
            return
        }
        let token = bridge.reloadToken
        if token != coordinator.lastReloadToken {
            coordinator.lastReloadToken = token
            DispatchQueue.main.async {
                uiView.reload()
            }
        }
    }

    static func dismantleUIView(_ uiView: WKWebView, coordinator: Coordinator) {
        uiView.configuration.userContentController.removeScriptMessageHandler(forName: SubtitleBridgeNames.scriptHandler)
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
        var parent: YouTubePlayerView
        weak var webView: WKWebView?
        var lastReloadToken = 0
        var lastLoadedURL: URL?

        init(_ parent: YouTubePlayerView) {
            self.parent = parent
        }

        nonisolated func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            parent.bridge.handleRawMessage(message.body as? [String: Any] ?? [:])
        }

        nonisolated func webView(_ webView: WKWebView,
                                 didFailProvisionalNavigation navigation: WKNavigation!,
                                 withError error: Error) {
            let desc = error.localizedDescription
            print("[WebView] 加载失败: \(desc)")
            Task { @MainActor in
                parent.bridge.webError = "加载失败：\(desc)"
            }
        }

        nonisolated func webView(_ webView: WKWebView,
                                 didFail navigation: WKNavigation!,
                                 withError error: Error) {
            let desc = error.localizedDescription
            print("[WebView] 导航失败: \(desc)")
        }

        nonisolated func webView(_ webView: WKWebView,
                                 didFinish navigation: WKNavigation!) {
            Task { @MainActor in
                parent.bridge.webError = nil
            }
        }
    }
}