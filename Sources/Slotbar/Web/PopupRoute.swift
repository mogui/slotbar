import Foundation

/// What a Slot does with a `window.open` / `target=_blank` popup (SPEC 7.3).
enum PopupRoute: Equatable {
    /// Open a Child window (SPEC 4.7).
    case childWindow
    /// Open a Child window and enter Sign-in mode for the Slot (SPEC 7.2).
    case signIn
    /// No window; hand the URL to macOS (`NSWorkspace.shared.open`).
    case browser(URL)
    /// No window; show this other Slot and load the URL there (SPEC 6.2).
    case slot(UUID, URL)
    /// No window and nothing opened: a blank popup from a foreign page has nothing to hand to the browser.
    case discard
}

/// Routes the popup target by the link rules (SPEC 7.1) from the Slot that owns the opener.
func popupRoute(url: URL?, openerURL: URL?, from source: Slot, slots: [Slot],
                inSignInMode: Bool, opensOutside: Bool) -> PopupRoute {
    guard let url, !url.absoluteString.isEmpty, url.absoluteString != "about:blank" else {
        let openerOnHomeHost = openerURL?.host()?.lowercased() == NavigationRouter.homeHost(source)
        return openerOnHomeHost || inSignInMode ? .childWindow : .discard
    }
    let request = NavigationRequest(url: url, isMainFrame: true, isExempt: false, opensOutside: opensOutside)
    // Sign-in mode keeps web popups in the app; Cmd/middle-click and other schemes still leave it.
    let scheme = url.scheme?.lowercased() ?? ""
    let staysInSignIn = !opensOutside && (["http", "https"].contains(scheme) || NavigationRouter.pageLocalSchemes.contains(scheme))
    switch NavigationRouter.route(request, from: source, slots: slots, inSignInMode: inSignInMode && staysInSignIn) {
    case .browser(let target): return .browser(target)
    case .slot(let id, let target) where id != source.id: return .slot(id, target)
    case .signIn: return .signIn
    default: return .childWindow
    }
}
