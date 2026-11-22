import UIKit
import WebKit

/// Avoids the retain cycle between WKUserContentController and the view controller.
private final class WeakHandler: NSObject, WKScriptMessageHandler {
    weak var target: WKScriptMessageHandler?
    init(_ target: WKScriptMessageHandler) { self.target = target }
    func userContentController(_ c: WKUserContentController, didReceive message: WKScriptMessage) {
        target?.userContentController(c, didReceive: message)
    }
}

final class WebViewController: UIViewController, WKScriptMessageHandler, WKNavigationDelegate, WKUIDelegate {
    private var webView: WKWebView!
    private var lightStatusBar = false
    private let sky = UIColor(red: 0x6c / 255.0, green: 0xc3 / 255.0, blue: 0xf0 / 255.0, alpha: 1)

    override func loadView() {
        let content = WKUserContentController()
        let handler = WeakHandler(self)
        ["haptic", "statusbar"].forEach { content.add(handler, name: $0) }
        content.addUserScript(WKUserScript(source: "window.__IS_APP = true;", injectionTime: .atDocumentStart, forMainFrameOnly: true))

        let config = WKWebViewConfiguration()
        config.userContentController = content
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        config.websiteDataStore = .default()

        webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.isOpaque = false
        webView.backgroundColor = sky
        webView.scrollView.backgroundColor = sky
        webView.scrollView.bounces = false
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.allowsLinkPreview = false
        if #available(iOS 16.4, *) { webView.isInspectable = true }
        view = webView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = sky
        guard let index = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "web") else {
            webView.loadHTMLString("<h2 style='font-family:-apple-system;padding:40px'>web/index.html missing</h2>", baseURL: nil)
            return
        }
        webView.loadFileURL(index, allowingReadAccessTo: index.deletingLastPathComponent())
    }

    override var preferredStatusBarStyle: UIStatusBarStyle { lightStatusBar ? .lightContent : .darkContent }
    override var prefersHomeIndicatorAutoHidden: Bool { true }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .portrait }

    // MARK: - JS bridge

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        switch message.name {
        case "haptic":
            haptic(message.body as? String ?? "light")
        case "statusbar":
            lightStatusBar = (message.body as? String) == "light"
            let bg = lightStatusBar ? UIColor.black : sky
            webView.backgroundColor = bg
            webView.scrollView.backgroundColor = bg
            UIView.animate(withDuration: 0.6) { self.setNeedsStatusBarAppearanceUpdate() }
        default:
            break
        }
    }

    private func haptic(_ kind: String) {
        switch kind {
        case "success": UINotificationFeedbackGenerator().notificationOccurred(.success)
        case "error": UINotificationFeedbackGenerator().notificationOccurred(.error)
        case "heavy": UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        case "medium": UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        default: UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }

    // MARK: - Navigation

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if navigationAction.navigationType == .linkActivated,
           let url = navigationAction.request.url, url.scheme == "http" || url.scheme == "https" {
            UIApplication.shared.open(url)
            decisionHandler(.cancel)
            return
        }
        decisionHandler(.allow)
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        webView.reload()
    }

    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let a = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "好", style: .default) { _ in completionHandler() })
        present(a, animated: true)
    }
}
