import AppKit
import WebKit

private let log = Log.logger("Web")

/// Turns attachments, unshowable responses and `<a download>` into `WKDownload`s saved to ~/Downloads (SPEC 7.4).
/// `SlotController`, the Slot webviews' navigation delegate, forwards response policy and new downloads here.
@MainActor
final class DownloadManager: NSObject, WKNavigationDelegate, WKDownloadDelegate {
    static let shared = DownloadManager()

    private var destinations: [ObjectIdentifier: URL] = [:]

    // MARK: WKNavigationDelegate

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping @MainActor (WKNavigationActionPolicy) -> Void) {
        decisionHandler(navigationAction.shouldPerformDownload ? .download : .allow)
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping @MainActor (WKNavigationResponsePolicy) -> Void) {
        let disposition = (navigationResponse.response as? HTTPURLResponse)?.value(forHTTPHeaderField: "Content-Disposition")
        let download = DownloadPolicy.shouldDownload(contentDisposition: disposition, canShowMIMEType: navigationResponse.canShowMIMEType)
        decisionHandler(download ? .download : .allow)
    }

    func webView(_ webView: WKWebView, navigationAction: WKNavigationAction, didBecome download: WKDownload) {
        download.delegate = self
    }

    func webView(_ webView: WKWebView, navigationResponse: WKNavigationResponse, didBecome download: WKDownload) {
        download.delegate = self
    }

    // MARK: WKDownloadDelegate

    func download(_ download: WKDownload, decideDestinationUsing response: URLResponse, suggestedFilename: String, completionHandler: @escaping @MainActor (URL?) -> Void) {
        let fileManager = FileManager.default
        let directory = fileManager.urls(for: .downloadsDirectory, in: .userDomainMask)[0]
        let destination = DownloadDestination.uniqueURL(in: directory, suggestedFilename: suggestedFilename) {
            fileManager.fileExists(atPath: $0.path)
        }
        destinations[ObjectIdentifier(download)] = destination
        completionHandler(destination)
    }

    func downloadDidFinish(_ download: WKDownload) {
        guard let destination = destinations.removeValue(forKey: ObjectIdentifier(download)) else { return }
        // Bounces the Dock Downloads stack.
        DistributedNotificationCenter.default().post(name: Notification.Name("com.apple.DownloadFileFinished"), object: destination.path)
    }

    func download(_ download: WKDownload, didFailWithError error: any Error, resumeData: Data?) {
        let destination = destinations.removeValue(forKey: ObjectIdentifier(download))
        log.error("Download failed: \(error.localizedDescription, privacy: .public)")
        if let destination, FileManager.default.fileExists(atPath: destination.path) {
            do {
                try FileManager.default.removeItem(at: destination)
            } catch {
                log.error("Could not remove partial download: \(error.localizedDescription, privacy: .public)")
            }
        }
    }
}
