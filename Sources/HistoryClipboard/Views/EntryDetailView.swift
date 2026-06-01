import SwiftUI

/// 条目详情视图（双击或右键菜单 → 查看详情）
struct EntryDetailView: View {
    let entry: ClipboardEntry
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 标题栏
            HStack {
                Image(systemName: entry.contentType.iconName)
                    .font(.title2)
                    .foregroundColor(.accentBlue)

                Text(entry.contentType.displayName)
                    .font(.headline)

                Spacer()

                Button("关闭") { dismiss() }
                    .buttonStyle(.plain)
                    .foregroundColor(.accentBlue)
            }

            Divider()

            // 详情
            detailRow("时间", entry.createdAt.formatted(date: .long, time: .shortened))
            detailRow("类型", entry.contentType.displayName)
            detailRow("来源", entry.sourceApp.isEmpty ? "未知" : entry.sourceApp)

            if !entry.formattedSize.isEmpty {
                detailRow("大小", entry.formattedSize)
            }

            switch entry.contentType {
            case .text, .url:
                detailRow("内容", "")
                ScrollView {
                    Text(entry.textContent)
                        .font(.system(size: 13, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(Color(white: 0.97))
                        .cornerRadius(8)
                }
                .frame(maxHeight: 200)
            case .image:
                if let data = entry.imageData, let nsImage = NSImage(data: data) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 200)
                        .cornerRadius(8)
                }
            case .file:
                detailRow("路径", entry.filePath)
            }

            Spacer()

            // 操作按钮
            HStack {
                Button("复制到剪贴板") {
                    copyToClipboard()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.accentBlue)
            }
        }
        .padding(20)
        .frame(width: 420, height: 400)
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(label + "：")
                .font(.system(size: 12))
                .foregroundColor(.secondaryGray)
                .frame(width: 50, alignment: .trailing)
            if !value.isEmpty {
                Text(value)
                    .font(.system(size: 12))
            }
        }
    }

    private func copyToClipboard() {
        switch entry.contentType {
        case .text, .url:
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(entry.textContent, forType: .string)
        case .image:
            if let data = entry.imageData {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setData(data, forType: .png)
            }
        case .file:
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(entry.filePath, forType: .string)
        }
    }
}
