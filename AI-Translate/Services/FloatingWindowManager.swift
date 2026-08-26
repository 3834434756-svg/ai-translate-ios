import SwiftUI
import UIKit
import AVKit
import AVFoundation

/// 系统级真画中画 (Picture-in-Picture) 悬浮窗。
/// 使用 AVPictureInPictureVideoCallViewController 作为内容源，
/// 让翻译文本以系统小气泡悬浮在其他 App（如 YouTube）之上，
/// 可拖动、后台持续显示、不影响任何 App 性能。
@MainActor
class FloatingWindowManager: NSObject, ObservableObject {
    @Published var isShowing = false

    private var pipController: AVPictureInPictureController?
    private var pipViewController: AVPictureInPictureVideoCallViewController?
    private var sourceView: UIView?
    private var label: UILabel?
    private var audioSessionActive = false

    var currentText: String {
        get { return _currentText }
        set {
            _currentText = newValue
            label?.text = newValue
        }
    }
    private var _currentText: String = ""

    func toggle(text: String) {
        if isShowing {
            hide()
        } else {
            show(text: text)
        }
    }

    func show(text: String) {
        guard AVPictureInPictureController.isPictureInPictureSupported() else { return }
        guard pipController == nil else {
            updateText(text)
            return
        }
        _currentText = text

        // 保持活跃的音频会话，让 PiP 在退回后台后仍能持续。
        activateAudioSession()

        // 创建承载翻译内容的自定义 PiP 视图控制器
        let pipVC = AVPictureInPictureVideoCallViewController()
        pipVC.preferredContentSize = CGSize(width: 280, height: 110)
        pipVC.view.backgroundColor = UIColor.black.withAlphaComponent(0.9)
        pipVC.view.layer.cornerRadius = 16
        pipVC.view.layer.masksToBounds = true

        let label = UILabel(frame: pipVC.view.bounds.insetBy(dx: 16, dy: 16))
        label.text = text
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        label.numberOfLines = 0
        label.textAlignment = .center
        label.lineBreakMode = .byCharWrapping
        pipVC.view.addSubview(label)
        self.label = label

        // 源视图：系统用它作为画中画转场动画的来源锚点。
        // 必须挂到真实的 window 上，否则 startPictureInPicture 会静默失败。
        let source = UIView(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
        source.isHidden = false
        source.alpha = 0
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let window = scenes
            .flatMap { $0.windows }
            .first(where: { $0.isKeyWindow })
            ?? scenes.first?.windows.first
        if let targetWindow = window {
            targetWindow.addSubview(source)
        } else if let pipWinScene = scenes.first {
            let w = UIWindow(windowScene: pipWinScene)
            w.windowLevel = .alert
            w.isHidden = false
            w.addSubview(source)
        }
        sourceView = source

        let contentSource = AVPictureInPictureController.ContentSource(
            activeVideoCallSourceView: source,
            contentViewController: pipVC
        )
        let controller = AVPictureInPictureController(contentSource: contentSource)
        controller.delegate = self
        controller.canStartPictureInPictureAutomaticallyFromInline = true
        pipController = controller
        pipViewController = pipVC

        controller.startPictureInPicture()
        isShowing = true
    }

    func hide() {
        pipController?.stopPictureInPicture()
        sourceView?.removeFromSuperview()
        sourceView = nil
        label?.removeFromSuperview()
        label = nil
        pipViewController = nil
        pipController = nil
        isShowing = false
        deactivateAudioSession()
    }

    func updateText(_ text: String) {
        _currentText = text
        label?.text = text
    }

    @discardableResult
    func updateTextAndKeepShowing(_ text: String) -> Bool {
        guard isShowing else { return false }
        updateText(text)
        return true
    }
}

// MARK: - 音频会话（保证后台 PiP 持续）
extension FloatingWindowManager {
    private func activateAudioSession() {
        guard !audioSessionActive else { return }
        do {
            // 用 playback 类别，避免 playAndRecord 打断/干扰网页视频的声音
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
            audioSessionActive = true
        } catch {
            print("[PiP] 激活音频会话失败: \(error.localizedDescription)")
        }
    }

    private func deactivateAudioSession() {
        guard audioSessionActive else { return }
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        audioSessionActive = false
    }
}

// MARK: - AVPictureInPictureControllerDelegate
extension FloatingWindowManager: AVPictureInPictureControllerDelegate {
    nonisolated func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        Task { @MainActor in
            isShowing = false
            sourceView?.removeFromSuperview()
            sourceView = nil
            label?.removeFromSuperview()
            label = nil
            pipViewController = nil
            pipController = nil
            deactivateAudioSession()
        }
    }
}