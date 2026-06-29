import Foundation

enum ByteText {
    static func format(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB, .useTB]
        formatter.countStyle = .memory
        formatter.includesUnit = true
        formatter.includesCount = true
        return formatter.string(fromByteCount: Int64(bytes))
    }

    static func rate(_ bytesPerSecond: UInt64) -> String {
        "\(format(bytesPerSecond))/s"
    }
}

extension Double {
    var percentText: String {
        "\(Int((self * 100).rounded()))%"
    }
}
