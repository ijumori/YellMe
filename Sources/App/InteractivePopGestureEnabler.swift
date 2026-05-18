import SwiftUI
import UIKit

/// `NavigationStack` で push した先が `ScrollView` 中心だと、画面左端のスワイプで戻りにくいことがある。
/// 親 `UINavigationController` の `interactivePopGestureRecognizer` を有効化し、他ジェスチャと同時認識させる。
struct InteractivePopGestureEnabler: UIViewControllerRepresentable {
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIViewController(context: Context) -> EnablingViewController {
        let vc = EnablingViewController()
        vc.coordinator = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: EnablingViewController, context: Context) {
        uiViewController.coordinator = context.coordinator
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        private weak var navigationController: UINavigationController?
        private weak var originalDelegate: UIGestureRecognizerDelegate?

        func attach(from host: UIViewController) {
            guard let nav = Self.findNavigationController(from: host) else { return }
            navigationController = nav
            guard let pop = nav.interactivePopGestureRecognizer else { return }
            if pop.delegate !== self {
                originalDelegate = pop.delegate
                pop.delegate = self
            }
            pop.isEnabled = true
        }

        func detachIfNeeded(from host: UIViewController) {
            guard host.isMovingFromParent else { return }
            guard let nav = navigationController,
                  let pop = nav.interactivePopGestureRecognizer,
                  pop.delegate === self else { return }
            pop.delegate = originalDelegate
            originalDelegate = nil
            navigationController = nil
        }

        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            (navigationController?.viewControllers.count ?? 0) > 1
        }

        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            true
        }

        private static func findNavigationController(from host: UIViewController) -> UINavigationController? {
            if let nav = host.navigationController { return nav }
            var current: UIViewController? = host.parent
            while let c = current {
                if let nav = c as? UINavigationController { return nav }
                current = c.parent
            }
            return nil
        }
    }

    final class EnablingViewController: UIViewController {
        var coordinator: Coordinator?

        override func viewDidLoad() {
            super.viewDidLoad()
            view.isUserInteractionEnabled = false
            view.backgroundColor = .clear
        }

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            coordinator?.attach(from: self)
        }

        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            coordinator?.detachIfNeeded(from: self)
        }
    }
}
