import Foundation

/// 剪贴板内容类型
enum ContentType: String, CaseIterable {
    case text  = "文本"
    case url   = "链接"
    case image = "图片"
    case file  = "文件"

    /// 用于筛选显示的标签
    var displayName: String {
        self.rawValue
    }

    /// SF Symbol 图标名
    var iconName: String {
        switch self {
        case .text:  return "doc.text"
        case .url:   return "link"
        case .image: return "photo"
        case .file:  return "doc"
        }
    }

    /// 数据库存储值
    var dbValue: String {
        switch self {
        case .text:  return "text"
        case .url:   return "url"
        case .image: return "image"
        case .file:  return "file"
        }
    }

    /// 从数据库值还原
    static func fromDB(_ value: String) -> ContentType {
        switch value {
        case "url":   return .url
        case "image": return .image
        case "file":  return .file
        default:      return .text
        }
    }
}
