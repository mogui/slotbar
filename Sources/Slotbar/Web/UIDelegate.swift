import AppKit
import WebKit

/// Popups (SPEC 7.3), JS dialogs and file pickers as sheets on the owning window; media capture and geolocation denied (SPEC 7.4, 7.6).
@MainActor
final class UIDelegate: NSObject, WKUIDelegate {
    static let shared = UIDelegate()
    /// `window.open` / `target=_blank` from a Slot or Child window webview (SPEC 7.3); nil = no window.
    var openPopup: ((_ opener: WKWebView, WKWebViewConfiguration, WKNavigationAction, WKWindowFeatures) -> WKWebView?)?
    /// The page called `window.close()`.
    var closeWebView: ((WKWebView) -> Void)?

    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        openPopup?(webView, configuration, navigationAction, windowFeatures)
    }

    func webViewDidClose(_ webView: WKWebView) {
        closeWebView?(webView)
    }

    // Async forms: the completion-handler forms are declared with different closure isolation in the macOS 26
    // and 27 SDKs, so a method matching one SDK silently misses the requirement in the other.
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo) async {
        let alert = Self.alert(message, frame: frame)
        alert.addButton(withTitle: "OK")
        _ = await present(alert, on: webView)
    }

    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo) async -> Bool {
        let alert = Self.alert(message, frame: frame)
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        return await present(alert, on: webView) == .alertFirstButtonReturn
    }

    func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo) async -> String? {
        let alert = Self.alert(prompt, frame: frame)
        let field = NSTextField(frame: NSRect(x: 0, y: 0, width: 260, height: 24))
        field.stringValue = defaultText ?? ""
        alert.accessoryView = field
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        alert.window.initialFirstResponder = field
        return await present(alert, on: webView) == .alertFirstButtonReturn ? field.stringValue : nil
    }

    func webView(_ webView: WKWebView, runOpenPanelWith parameters: WKOpenPanelParameters, initiatedByFrame frame: WKFrameInfo) async -> [URL]? {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = parameters.allowsMultipleSelection
        panel.canChooseDirectories = parameters.allowsDirectories
        panel.canChooseFiles = true
        guard let window = webView.window else { return nil }
        return await panel.beginSheetModal(for: window) == .OK ? panel.urls : nil
    }

    func webView(_ webView: WKWebView, decideMediaCapturePermissionsFor origin: WKSecurityOrigin, initiatedBy frame: WKFrameInfo, type: WKMediaCaptureType) async -> WKPermissionDecision {
        .deny
    }

    @available(macOS 27.0, *)
    func webView(_ webView: WKWebView, requestGeolocationPermissionFor origin: WKSecurityOrigin, initiatedByFrame frame: WKFrameInfo, decisionHandler: @escaping @MainActor (WKPermissionDecision) -> Void) {
        decisionHandler(.deny)
    }

    private static func alert(_ message: String, frame: WKFrameInfo) -> NSAlert {
        let alert = NSAlert()
        alert.messageText = frame.securityOrigin.host
        alert.informativeText = message
        return alert
    }

    private func present(_ alert: NSAlert, on webView: WKWebView) async -> NSApplication.ModalResponse {
        guard let window = webView.window else { return alert.runModal() }
        return await alert.beginSheetModal(for: window)
    }
}
