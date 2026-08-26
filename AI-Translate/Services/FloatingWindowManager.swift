import SwiftUI
import UIKit

@MainActor
class FloatingWindowManager: NSObject, ObservableObject {
    @Published var isShowing = false
    private var floatingWindow: UIWindow?
    private var textLabel: UILabel?
    private var panGesture: UIPanGestureRecognizer?

    func toggle(text: String) {
        if isShowing {
            hide()
        } else {
            show(text: text)
        }
    }

    func show(text: String) {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        let window = UIWindow(windowScene: scene)
        window.windowLevel = .alert + 1
        window.backgroundColor = .clear

        let container = UIView(frame: CGRect(x: 40, y: 100, width: scene.screen.bounds.width - 80, height: 160))
        container.backgroundColor = UIColor.black.withAlphaComponent(0.85)
        container.layer.cornerRadius = 16
        container.layer.borderWidth = 1
        container.layer.borderColor = UIColor.systemTeal.cgColor

        let label = UILabel(frame: container.bounds.insetBy(dx: 16, dy: 16))
        label.text = text
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.numberOfLines = 0
        label.textAlignment = .center
        container.addSubview(label)
        textLabel = label

        // 拖动手势
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        container.addGestureRecognizer(pan)
        panGesture = pan

        // 点击隐藏
        let tap = UITapGestureRecognizer(target: self, action: #selector(hide))
        container.addGestureRecognizer(tap)

        window.addSubview(container)
        window.isHidden = false
        floatingWindow = window
        isShowing = true
    }

    @objc func hide() {
        floatingWindow?.isHidden = true
        floatingWindow = nil
        textLabel = nil
        isShowing = false
    }

    func updateText(_ text: String) {
        textLabel?.text = text
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let view = gesture.view else { return }
        let translation = gesture.translation(in: view.superview)
        view.center = CGPoint(x: view.center.x + translation.x, y: view.center.y + translation.y)
        gesture.setTranslation(.zero, in: view.superview)
    }
}
