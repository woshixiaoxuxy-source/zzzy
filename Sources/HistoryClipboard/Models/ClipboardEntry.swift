import Foundation

/// 剪贴板历史条目
struct ClipboardEntry: Identifiable, Equatable {
    let id: Int64
    var contentType: ContentType
    var textContent: String
    var imageData: Data?
    var filePath: String
    var sourceApp: String
    var sizeBytes: Int64
    var isPinned: Bool
    var isStarred: Bool
    var createdAt: Date

    /// 格式化的大小
    var formattedSize: String {
        if sizeBytes <= 0 { return "" }
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: sizeBytes)
    }

    /// 相对时间描述（如"3分钟前"）
    var relativeTime: String {
        let now = Date()
        let interval = now.timeIntervalSince(createdAt)

        if interval < 60 {
            return "刚刚"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes) 分钟前"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours) 小时前"
        } else if interval < 2592000 {
            let days = Int(interval / 86400)
            return "\(days) 天前"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MM/dd"
            return formatter.string(from: createdAt)
        }
    }

    /// 简短预览文本
    var previewText: String {
        switch contentType {
        case .text, .url:
            let trimmed = textContent.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.count > 80 {
                return String(trimmed.prefix(80)) + "…"
            }
            return trimmed.isEmpty ? "(空白内容)" : trimmed
        case .image:
            if let data = imageData {
                return "图片 (\(data.count.formatted()) bytes)"
            }
            return "图片"
        case .file:
            let name = URL(fileURLWithPath: filePath).lastPathComponent
            return "文件: \(name)"
        }
    }

    /// 格式化时间
    var formattedTime: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(createdAt) {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            return formatter.string(from: createdAt)
        } else if calendar.isDateInYesterday(createdAt) {
            return "昨天"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MM/dd HH:mm"
            return formatter.string(from: createdAt)
        }
    }

    static func == (lhs: ClipboardEntry, rhs: ClipboardEntry) -> Bool {
        lhs.id == rhs.id
    }
}
