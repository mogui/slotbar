import Foundation
import Testing
@testable import Slotbar

@Suite struct NavigationRouterTests {
    static let work = UUID()
    static let personal = UUID()
    static func slot(_ url: String, profile: UUID = work) -> Slot {
        Slot(id: UUID(), url: URL(string: url)!, profileId: profile, label: nil, keepAlive: true, notifications: true)
    }

    let mail = slot("https://mail.google.com/mail/u/0/")
    let calendar = slot("https://calendar.google.com/")
    let personalDrive = slot("https://drive.google.com/", profile: personal)

    func route(_ url: String, from source: Slot? = nil, isMainFrame: Bool = true, isExempt: Bool = false,
               opensOutside: Bool = false, inSignInMode: Bool = false) -> Route {
        NavigationRouter.route(
            NavigationRequest(url: URL(string: url)!, isMainFrame: isMainFrame, isExempt: isExempt, opensOutside: opensOutside),
            from: source ?? mail, slots: [mail, calendar, personalDrive], inSignInMode: inSignInMode)
    }

    @Test func homeHostStaysInSlot() {
        #expect(route("https://mail.google.com/mail/u/0/#inbox/123") == .stay)
    }

    @Test func otherHostGoesToSameProfileSlotWithThatHomeHost() {
        #expect(route("https://calendar.google.com/r/eventedit?eid=1") ==
                .slot(calendar.id, URL(string: "https://calendar.google.com/r/eventedit?eid=1")!))
    }

    @Test func otherHostWithoutSlotGoesToDefaultBrowser() {
        #expect(route("https://example.com/a") == .browser(URL(string: "https://example.com/a")!))
    }

    @Test func neverRoutesToSlotOfAnotherProfile() {
        #expect(route("https://drive.google.com/file/d/1") == .browser(URL(string: "https://drive.google.com/file/d/1")!))
    }

    @Test func subFramesLoadInPlace() {
        #expect(route("https://example.com/embed", isMainFrame: false) == .stay)
    }

    @Test func serverRedirectsAndOwnLoadsAreNeverRouted() {
        #expect(route("https://example.com/landing", isExempt: true) == .stay)
    }

    @Test func cmdOrMiddleClickAlwaysGoesToDefaultBrowserEvenOnHomeHost() {
        #expect(route("https://mail.google.com/mail/u/0/#inbox/1", opensOutside: true) ==
                .browser(URL(string: "https://mail.google.com/mail/u/0/#inbox/1")!))
    }

    @Test(arguments: ["mailto:a@example.com", "tel:+391234", "zoommtg://zoom.us/join?confno=1"])
    func otherSchemesGoToTheirMacOSHandler(url: String) {
        #expect(route(url) == .browser(URL(string: url)!))
    }

    @Test(arguments: ["about:blank", "blob:https://mail.google.com/0f1c", "data:text/plain,hi", "javascript:void(0)"])
    func pageLocalSchemesLoadInPlace(url: String) {
        #expect(route(url) == .stay)
    }

    @Test func googleURLWrapperIsUnwrappedAndTheTargetRouted() {
        #expect(route("https://www.google.com/url?q=https://calendar.google.com/r/day&sa=D") ==
                .slot(calendar.id, URL(string: "https://calendar.google.com/r/day")!))
    }

    @Test func urlParameterWrapperOnAnyGoogleTLDIsUnwrapped() {
        #expect(route("https://google.co.uk/url?url=https%3A%2F%2Fexample.com%2Fx%3Fa%3D1") ==
                .browser(URL(string: "https://example.com/x?a=1")!))
    }

    @Test func wrapperTargetOnHomeHostLoadsInTheSourceSlot() {
        #expect(route("https://www.google.com/url?q=https://mail.google.com/mail/u/0/%23inbox") ==
                .slot(mail.id, URL(string: "https://mail.google.com/mail/u/0/#inbox")!))
    }

    @Test(arguments: ["https://www.google.com/url?sa=D", "https://www.google.com/url?q=javascript:alert(1)",
                      "https://www.google.com/url?q=/relative"])
    func wrapperWithoutAbsoluteHTTPTargetOpensAsIsInDefaultBrowser(url: String) {
        #expect(route(url) == .browser(URL(string: url)!))
    }

    @Test func meetGoesToDefaultBrowser() {
        #expect(route("https://meet.google.com/abc-defg-hij") == .browser(URL(string: "https://meet.google.com/abc-defg-hij")!))
    }

    @Test func meetStaysInSameProfileSlotWithMeetHomeHost() {
        let meet = Self.slot("https://meet.google.com/")
        let route = NavigationRouter.route(
            NavigationRequest(url: URL(string: "https://meet.google.com/abc")!, isMainFrame: true, isExempt: false, opensOutside: false),
            from: mail, slots: [mail, meet], inSignInMode: false)
        #expect(route == .slot(meet.id, URL(string: "https://meet.google.com/abc")!))
    }

    @Test(arguments: ["https://accounts.google.com/v3/signin/identifier", "https://accounts.google.co.uk/ServiceLogin",
                      "https://accounts.google.it/", "https://accounts.youtube.com/accounts/SetSID"])
    func signInHostsEnterSignInMode(url: String) {
        #expect(route(url) == .signIn)
    }

    @Test func serverRedirectToSignInHostEntersSignInMode() {
        #expect(route("https://accounts.google.com/ServiceLogin?continue=x", isExempt: true) == .signIn)
    }

    @Test(arguments: ["https://login.microsoftonline.com/common/oauth2", "https://myaccount.google.com/",
                      "https://calendar.google.com/"])
    func inSignInModeEveryMainFrameNavigationStays(url: String) {
        #expect(route(url, inSignInMode: true) == .stay)
    }

    @Test func accountsOnLookalikeDomainIsNotASignInHost() {
        #expect(route("https://accounts.google.evil.example/") == .browser(URL(string: "https://accounts.google.evil.example/")!))
    }
}
