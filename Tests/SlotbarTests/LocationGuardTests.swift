import Testing
@testable import Slotbar

@Suite struct LocationGuardTests {
    let home = "/Users/ada"

    @Test func inApplicationsNeedsNoMove() {
        #expect(!LocationGuard.needsMove(bundlePath: "/Applications/Slotbar.app", homeDirectory: home))
    }

    @Test func inDownloadsNeedsMove() {
        #expect(LocationGuard.needsMove(bundlePath: "/Users/ada/Downloads/Slotbar.app", homeDirectory: home))
    }

    @Test func inUserApplicationsNeedsNoMove() {
        #expect(!LocationGuard.needsMove(bundlePath: "/Users/ada/Applications/Slotbar.app", homeDirectory: home))
    }
}

extension LocationGuardTests {
    @Test(arguments: ["/Applications-old/Slotbar.app", "/Applicationsfoo/Slotbar.app", "/Users/ada/ApplicationsX/Slotbar.app"])
    func siblingFolderNeedsMove(path: String) {
        #expect(LocationGuard.needsMove(bundlePath: path, homeDirectory: home))
    }

    @Test func nestedInApplicationsNeedsNoMove() {
        #expect(!LocationGuard.needsMove(bundlePath: "/Applications/Utilities/Slotbar.app", homeDirectory: home))
    }

    @Test func dotDotOutOfApplicationsNeedsMove() {
        #expect(LocationGuard.needsMove(bundlePath: "/Applications/../Users/ada/Slotbar.app", homeDirectory: home))
    }

    @Test func translocatedNeedsMove() {
        let path = "/private/var/folders/xy/T/AppTranslocation/1234-ABCD/d/Slotbar.app"
        #expect(LocationGuard.needsMove(bundlePath: path, homeDirectory: home))
    }

    @Test func translocatedUnderApplicationsNeedsMove() {
        #expect(LocationGuard.needsMove(bundlePath: "/Applications/AppTranslocation/X/d/Slotbar.app", homeDirectory: home))
    }
}
