import Testing
@testable import Slotbar

@Suite struct DownloadPolicyTests {
    @Test func attachmentDispositionIsAnAttachment() {
        #expect(DownloadPolicy.isAttachment(contentDisposition: "attachment"))
    }

    @Test(arguments: ["Attachment", "attachment; filename=\"report.pdf\"", "  ATTACHMENT ;filename*=UTF-8''r.pdf"])
    func attachmentTokenIsCaseInsensitiveWithParameters(_ header: String) {
        #expect(DownloadPolicy.isAttachment(contentDisposition: header))
    }

    @Test(arguments: [nil, "", "inline", "inline; filename=\"attachment.pdf\""] as [String?])
    func inlineOrMissingDispositionIsNotAnAttachment(_ header: String?) {
        #expect(!DownloadPolicy.isAttachment(contentDisposition: header))
    }

    @Test func attachmentDownloadsEvenWhenShowable() {
        #expect(DownloadPolicy.shouldDownload(contentDisposition: "attachment", canShowMIMEType: true))
    }

    @Test func unshowableMIMETypeDownloads() {
        #expect(DownloadPolicy.shouldDownload(contentDisposition: nil, canShowMIMEType: false))
    }

    @Test func showableInlineResponseIsShown() {
        #expect(!DownloadPolicy.shouldDownload(contentDisposition: "inline; filename=a.pdf", canShowMIMEType: true))
    }
}
