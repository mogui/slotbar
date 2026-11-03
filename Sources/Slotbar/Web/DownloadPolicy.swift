import Foundation

/// Which navigation responses become downloads (SPEC 7.4).
enum DownloadPolicy {
    /// The disposition type (before any `;` parameters) is `attachment`, case-insensitive.
    static func isAttachment(contentDisposition: String?) -> Bool {
        guard let contentDisposition else { return false }
        let type = contentDisposition.split(separator: ";", omittingEmptySubsequences: false).first ?? ""
        return type.trimmingCharacters(in: .whitespaces).lowercased() == "attachment"
    }

    static func shouldDownload(contentDisposition: String?, canShowMIMEType: Bool) -> Bool {
        isAttachment(contentDisposition: contentDisposition) || !canShowMIMEType
    }
}
