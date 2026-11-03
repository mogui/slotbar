import Foundation

/// Picks where a download lands (SPEC 7.4).
enum DownloadDestination {
    /// `<directory>/<name>`, or `<stem> (N).<ext>` with the first free N.
    static func uniqueURL(in directory: URL, suggestedFilename: String, exists: (URL) -> Bool) -> URL {
        let filename = sanitized(suggestedFilename)
        let name = filename as NSString
        let ext = name.pathExtension
        let stem = name.deletingPathExtension
        var candidate = directory.appendingPathComponent(filename, isDirectory: false)
        var counter = 1
        while exists(candidate) {
            let numbered = ext.isEmpty ? "\(stem) (\(counter))" : "\(stem) (\(counter)).\(ext)"
            candidate = directory.appendingPathComponent(numbered, isDirectory: false)
            counter += 1
        }
        return candidate
    }

    /// Last non-empty `/`-separated component; `download` when that is empty, `.` or `..`.
    private static func sanitized(_ suggested: String) -> String {
        let last = suggested.split(separator: "/").last.map(String.init) ?? ""
        return ["", ".", ".."].contains(last) ? "download" : last
    }
}
