import Foundation
import WebKit

/// 英文脚本安全名，Swift 侧与注入 JS 共用
enum SubtitleBridgeNames {
    static let scriptHandler = "subtitleBridge"
}

/// 桥接器：注入 JS 读取油管字幕轨(CC)的每一条字幕，
/// 回传给 Swift 做翻译，并显示到画中画/叠加层。
@MainActor
final class SubtitleBridge: NSObject, ObservableObject {
    @Published var currentSubtitle = ""
    @Published var translatedSubtitle = ""
    @Published var webError: String?
    @Published var reloadToken = 0
    @Published var targetURL: URL?
    @Published var statusText = "等待连接到频道字幕…"

    private weak var floatingWindow: FloatingWindowManager?
    private let translationService: TranslationService
    private var pendingText = ""

    init(floatingWindow: FloatingWindowManager, translationService: TranslationService) {
        self.floatingWindow = floatingWindow
        self.translationService = translationService
        super.init()
    }

    /// 用户点击油管内置 CC 字幕：此开关控制播放器的控制按钮，由页面自身处理。
    /// JS 侧无论 CC 是否可见，只要字幕轨有 active cue 就会回传。

    /// 注入到页面的脚本（document end），监听字幕轨 cuechange。
    static func injectedScript() -> WKUserScript {
        let source = """
        (function() {
          var handlerName = '\(SubtitleBridgeNames.scriptHandler)';
          function post(text) {
            if (text && window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers[handlerName]) {
              window.webkit.messageHandlers[handlerName].postMessage({type:'cue', text:text});
            }
          }
          function clean(html) {
            var el = document.createElement('div');
            el.innerHTML = html || '';
            return el.textContent.replace(/\\n/g, ' ').replace(/\\s+/g, ' ').trim();
          }
          var lastPosted = '';
          function postIfChanged(text) {
            if (text && text !== lastPosted) {
              lastPosted = text;
              post(text);
            }
          }
          // 1) 读取 video.textTracks 的 cuechange
          function attachTrack(track) {
            if (track.__attached) return;
            track.__attached = true;
            track.addEventListener('cuechange', function() {
              if (track.activeCues && track.activeCues.length > 0) {
                postIfChanged(clean(track.activeCues[0].text));
              }
            });
          }
          // 2) 直接读油管渲染出来的字幕 DOM（更可靠）
          function readRendered() {
            var nodes = document.querySelectorAll(
              '.ytp-caption-segment, .captions-text, .ytp-caption-window-container .caption-visual-line, #ytp-caption-window-container .captions-text'
            );
            var parts = [];
            for (var i = 0; i < nodes.length; i++) {
              var t = clean(nodes[i].innerText || nodes[i].textContent);
              if (t) parts.push(t);
            }
            if (parts.length) postIfChanged(parts.join(' '));
          }
          function scan() {
            var videos = document.querySelectorAll('video');
            for (var i = 0; i < videos.length; i++) {
              var tracks = videos[i].textTracks;
              for (var j = 0; j < tracks.length; j++) attachTrack(tracks[j]);
            }
            readRendered();
          }
          function init() {
            scan();
            if (document.body) {
              new MutationObserver(function() { scan(); })
                .observe(document.body, {childList:true, subtree:true, characterData:true});
            }
            setInterval(scan, 1500);
          }
          if (document.readyState === 'loading') {
            document.addEventListener('DOMContentLoaded', init);
          } else {
            init();
          }
        })();
        """
        return WKUserScript(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
    }

    func reset() {
        currentSubtitle = ""
        translatedSubtitle = ""
        pendingText = ""
        statusText = "等待连接到视频…"
    }
}

// MARK: - WKScriptMessageHandler
extension SubtitleBridge: WKScriptMessageHandler {
    nonisolated func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == SubtitleBridgeNames.scriptHandler,
              let body = message.body as? [String: Any] else { return }
        handleRawMessage(body)
    }

    nonisolated func handleRawMessage(_ body: [String: Any]) {
        Task { @MainActor in
            processMessage(body)
        }
    }

    private func processMessage(_ body: [String: Any]) {
        guard let type = body["type"] as? String, type == "cue",
              let text = body["text"] as? String, !text.isEmpty,
              text != currentSubtitle else { return }
        currentSubtitle = text
        pendingText = text
        statusText = "已捕获字幕，翻译中…"
        Task {
            await translationService.translate(text)
            let translated = translationService.translatedText
            translatedSubtitle = translated
            statusText = "已翻译"
            // 更新画中画（若已开启）
            if floatingWindow?.isShowing == true {
                floatingWindow?.updateText(text + "\n——\n" + translated)
            }
        }
    }
}