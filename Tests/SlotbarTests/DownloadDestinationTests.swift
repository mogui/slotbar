import Foundation
import Testing
@testable import Slotbar

@Suite struct DownloadDestinationTests {
    let downloads = URL(fileURLWithPath: "/Users/me/Downloads", isDirectory: true)

    func destination(_ name: String, existing: Set<String> = []) -> String {
        DownloadDestination.uniqueURL(in: downloads, suggestedFilename: name) { existing.contains($0.lastPathComponent) }.path
    }

    @Test func freeNameIsUsedAsIs() {
        #expect(destination("report.pdf") == "/Users/me/Downloads/report.pdf")
    }

    @Test func clashAppendsCounterBeforeExtension() {
        #expect(destination("report.pdf", existing: ["report.pdf"]) == "/Users/me/Downloads/report (1).pdf")
    }

    @Test func counterKeepsGrowingUntilFree() {
        #expect(destination("report.pdf", existing: ["report.pdf", "report (1).pdf", "report (2).pdf"]) == "/Users/me/Downloads/report (3).pdf")
    }

    @Test func onlyTheLastExtensionIsKeptAfterTheCounter() {
        #expect(destination("archive.tar.gz", existing: ["archive.tar.gz"]) == "/Users/me/Downloads/archive.tar (1).gz")
    }

    @Test func nameWithoutExtensionGetsCounterAtTheEnd() {
        #expect(destination("README", existing: ["README"]) == "/Users/me/Downloads/README (1)")
    }

    @Test func dotfileHasNoExtension() {
        #expect(destination(".env", existing: [".env"]) == "/Users/me/Downloads/.env (1)")
    }

    @Test func slashContainingNameKeepsLastComponent() {
        #expect(destination("../../etc/passwd") == "/Users/me/Downloads/passwd")
    }

    @Test func trailingSlashKeepsLastNonEmptyComponent() {
        #expect(destination("photos/2026/") == "/Users/me/Downloads/2026")
    }

    @Test(arguments: ["", "/", "a/..", ".", "..", "x/."])
    func unusableNameFallsBackToDownload(_ name: String) {
        #expect(destination(name) == "/Users/me/Downloads/download")
    }
}
