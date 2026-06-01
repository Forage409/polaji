import Foundation

enum LocalTimeFormatter {
    private static let outputFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .autoupdatingCurrent
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()

    private static let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let isoFormatterWithoutFractionalSeconds = ISO8601DateFormatter()

    static func now() -> String {
        outputFormatter.string(from: Date())
    }

    static func display(_ raw: String) -> String {
        guard !raw.isEmpty, raw != "预览" else { return raw }
        if let date = isoFormatter.date(from: raw) ?? isoFormatterWithoutFractionalSeconds.date(from: raw) {
            return outputFormatter.string(from: date)
        }
        return raw
    }
}
