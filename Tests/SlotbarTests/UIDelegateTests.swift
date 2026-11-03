import Testing
import WebKit
@testable import Slotbar

@MainActor
@Suite struct UIDelegateTests {
    /// WebKit checks `respondsToSelector:`; a missed selector silently auto-dismisses page dialogs.
    @Test(arguments: [
        "webView:runJavaScriptAlertPanelWithMessage:initiatedByFrame:completionHandler:",
        "webView:runJavaScriptConfirmPanelWithMessage:initiatedByFrame:completionHandler:",
        "webView:runJavaScriptTextInputPanelWithPrompt:defaultText:initiatedByFrame:completionHandler:",
    ])
    func respondsToDialogSelectors(selector: String) {
        #expect(UIDelegate.shared.responds(to: NSSelectorFromString(selector)))
    }
}
