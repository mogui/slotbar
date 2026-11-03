import Foundation
import Testing
@testable import Slotbar

@Suite struct PopupRouteTests {
    static let work = UUID()
    static let personal = UUID()
    static func slot(_ url: String, profile: UUID = work) -> Slot {
        Slot(id: UUID(), url: URL(string: url)!, profileId: profile, label: nil, keepAlive: true, notifications: true)
    }

    let mail = slot("https://mail.google.com/mail/u/0/")
    let calendar = slot("https://calendar.google.com/")
    let personalDrive = slot("https://drive.google.com/", profile: personal)

    func route(_ url: String?, opener: String = "https://mail.google.com/mail/u/0/#inbox",
               inSignInMode: Bool = false, opensOutside: Bool = false) -> PopupRoute {
        popupRoute(url: url.flatMap(URL.init(string:)), openerURL: URL(string: opener), from: mail,
                   slots: [mail, calendar, personalDrive], inSignInMode: inSignInMode, opensOutside: opensOutside)
    }

    @Test func homeHostTargetOpensChildWindow() {
        #expect(route("https://mail.google.com/mail/u/0/?view=cm") == .childWindow)
    }

    @Test func foreignTargetGoesToDefaultBrowser() {
        #expect(route("https://example.com/doc") == .browser(URL(string: "https://example.com/doc")!))
    }

    @Test func sameProfileSlotHomeHostShowsThatSlotWithoutWindow() {
        #expect(route("https://calendar.google.com/event?eid=1") ==
                .slot(calendar.id, URL(string: "https://calendar.google.com/event?eid=1")!))
    }

    @Test func blankPopupFromHomeHostOpensChildWindow() {
        #expect(route("about:blank") == .childWindow)
        #expect(route(nil) == .childWindow)
        #expect(route("") == .childWindow)
    }

    @Test func blankPopupFromForeignOpenerOpensNothing() {
        #expect(route("about:blank", opener: "https://accounts.google.com/signin") == .discard)
        #expect(route(nil, opener: "https://example.com/") == .discard)
    }

    @Test func signInHostOpensChildWindowAndEntersSignInMode() {
        #expect(route("https://accounts.google.com/o/oauth2/auth") == .signIn)
    }

    @Test func inSignInModeEveryPopupStays() {
        #expect(route("https://idp.example.com/saml", inSignInMode: true) == .childWindow)
        #expect(route("about:blank", opener: "https://idp.example.com/", inSignInMode: true) == .childWindow)
    }

    @Test func cmdOrMiddleClickAlwaysGoesToBrowserEvenInSignInMode() {
        let home = URL(string: "https://mail.google.com/mail/u/0/#inbox/1")!
        #expect(route(home.absoluteString, opensOutside: true) == .browser(home))
        #expect(route(home.absoluteString, inSignInMode: true, opensOutside: true) == .browser(home))
    }

    @Test func nonWebSchemesGoToTheirHandlerEvenInSignInMode() {
        #expect(route("mailto:a@example.com", inSignInMode: true) == .browser(URL(string: "mailto:a@example.com")!))
    }
}
