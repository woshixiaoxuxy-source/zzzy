import SwiftUI

// MARK: - Color Extensions

extension Color {
    /// 主色调
    static let accentBlue = Color(red: 60/255, green: 150/255, blue: 200/255)

    /// 浅蓝背景
    static let lightBlue = Color(red: 140/255, green: 200/255, blue: 230/255)

    /// 置顶行背景
    static let pinnedBg = Color(red: 232/255, green: 244/255, blue: 252/255)

    /// 分隔线
    static let dividerGray = Color(red: 210/255, green: 210/255, blue: 210/255)

    /// 次要文字 — 深灰，确保可读
    static let secondaryGray = Color(red: 70/255, green: 70/255, blue: 75/255)

    /// 悬停高亮
    static let hoverBg = Color(red: 242/255, green: 248/255, blue: 254/255)
}

// MARK: - View Extensions

extension View {
    /// 应用圆角卡片风格
    func cardStyle() -> some View {
        self
            .background(Color.white)
            .cornerRadius(8)
    }
}

// MARK: - String Extensions

extension String {
    /// 判断字符串是否为 URL 格式
    var isURL: Bool {
        let pattern = #"^(https?|ftp|file)://"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return false
        }
        return regex.firstMatch(in: self, range: NSRange(location: 0, length: self.utf16.count)) != nil
    }

    /// 截断到指定字符数
    func truncated(_ maxLength: Int) -> String {
        if self.count > maxLength {
            return String(self.prefix(maxLength)) + "…"
        }
        return self
    }
}
