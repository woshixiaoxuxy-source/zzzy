import SwiftUI

/// 单条剪贴板历史记录行
struct EntryRow: View {
    let entry: ClipboardEntry
    let onCopy: () -> Void
    let onTogglePin: () -> Void
    let onToggleStar: () -> Void
    let onDelete: () -> Void

    @State private var isHovered = false
    @State private var showCopied = false

    var body: some View {
        HStack(spacing: 8) {
            // 类型图标
            Image(systemName: entry.contentType.iconName)
                .font(.system(size: 14))
                .foregroundColor(.accentBlue)
                .frame(width: 20)

            // 内容预览
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.previewText)
                    .font(.system(size: 15, weight: .medium))
                    .lineLimit(1)
                    .foregroundColor(.black)

                HStack(spacing: 6) {
                    Text(entry.formattedTime)
                        .font(.system(size: 12))
                        .foregroundColor(.secondaryGray)

                    if !entry.sourceApp.isEmpty {
                        Text("·")
                            .foregroundColor(.secondaryGray)
                        Text(entry.sourceApp)
                            .font(.system(size: 12))
                            .foregroundColor(.secondaryGray)
                    }

                    if !entry.formattedSize.isEmpty {
                        Text("·")
                            .foregroundColor(.secondaryGray)
                        Text(entry.formattedSize)
                            .font(.system(size: 12))
                            .foregroundColor(.secondaryGray)
                    }
                }
            }

            Spacer()

            // 操作按钮（悬停时显示）
            if isHovered {
                HStack(spacing: 4) {
                    // 星标
                    button(icon: entry.isStarred ? "star.fill" : "star",
                           color: entry.isStarred ? .yellow : .secondaryGray,
                           action: onToggleStar)

                    // 置顶
                    button(icon: entry.isPinned ? "pin.fill" : "pin",
                           color: entry.isPinned ? .accentBlue : .secondaryGray,
                           action: onTogglePin)

                    // 复制
                    button(icon: showCopied ? "checkmark" : "doc.on.doc",
                           color: showCopied ? .green : .secondaryGray,
                           action: {
                        onCopy()
                        showCopied = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                            showCopied = false
                        }
                    })

                    // 删除
                    button(icon: "trash", color: .red.opacity(0.6), action: onDelete)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            entry.isPinned
                ? Color.pinnedBg
                : (isHovered ? Color.hoverBg : Color.clear)
        )
        .cornerRadius(6)
        .padding(.horizontal, 8)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onCopy()
            showCopied = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                showCopied = false
            }
        }
    }

    private func button(icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(color)
                .frame(width: 24, height: 24)
        }
        .buttonStyle(.plain)
    }
}
