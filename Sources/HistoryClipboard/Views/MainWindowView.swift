import SwiftUI

/// 主窗口视图 —— 作为完整窗口显示的剪贴板管理界面
struct MainWindowView: View {
    @StateObject private var db = DatabaseManager.shared
    @State private var searchText = ""
    @State private var selectedType: ContentType? = nil
    @State private var showStarredOnly = false
    @State private var showDetailEntry: ClipboardEntry? = nil
    @State private var showSettings = false

    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Image(systemName: "clipboard")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.accentBlue)
                Text("历史粘贴板")
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
                Text("共 \(filteredEntries.count) 条")
                    .font(.system(size: 12))
                    .foregroundColor(.secondaryGray)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 8)

            // 筛选栏
            FilterBar(
                searchText: $searchText,
                selectedType: $selectedType,
                showStarredOnly: $showStarredOnly
            )

            Divider().padding(.top, 8)

            // 列表
            if filteredEntries.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "tray")
                        .font(.system(size: 40))
                        .foregroundColor(.lightBlue)
                    Text("暂无剪贴板历史")
                        .font(.system(size: 16))
                        .foregroundColor(.secondaryGray)
                    Text("试试复制一些内容，然后回到这里 ✨")
                        .font(.system(size: 13))
                        .foregroundColor(.lightBlue)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(filteredEntries) { entry in
                            EntryRow(
                                entry: entry,
                                onCopy: { copyEntry(entry) },
                                onTogglePin: { db.togglePin(entry) },
                                onToggleStar: { db.toggleStar(entry) },
                                onDelete: { db.deleteEntry(entry) }
                            )
                            .contextMenu {
                                Button("复制") { copyEntry(entry) }
                                Divider()
                                Button(entry.isPinned ? "取消置顶" : "置顶") { db.togglePin(entry) }
                                Button(entry.isStarred ? "取消星标" : "星标") { db.toggleStar(entry) }
                                Divider()
                                Button("查看详情") { showDetailEntry = entry }
                                Button("删除", role: .destructive) { db.deleteEntry(entry) }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }

            Divider()

            // 底部栏
            HStack {
                Button(action: { showSettings = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "gearshape")
                        Text("设置")
                    }
                    .font(.system(size: 12))
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondaryGray)

                Spacer()

                Text("点击条目复制内容  ·  双击查看详情")
                    .font(.system(size: 10))
                    .foregroundColor(.secondaryGray)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(Color.white)
        .sheet(item: $showDetailEntry) { entry in
            EntryDetailView(entry: entry)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }

    // MARK: - Filtered entries

    var filteredEntries: [ClipboardEntry] {
        var results = db.entries

        if !searchText.isEmpty {
            results = results.filter {
                $0.textContent.localizedCaseInsensitiveContains(searchText)
            }
        }
        if let type = selectedType {
            results = results.filter { $0.contentType == type }
        }
        if showStarredOnly {
            results = results.filter { $0.isStarred }
        }
        return results
    }

    // MARK: - Actions

    private func copyEntry(_ entry: ClipboardEntry) {
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
            if let url = URL(string: "file://\(entry.filePath)") {
                NSPasteboard.general.writeObjects([url as NSURL])
            }
        }
    }
}
