import SwiftUI

/// 菜单栏 Popover 主视图
struct MenuBarView: View {
    @StateObject private var db = DatabaseManager.shared
    @State private var searchText = ""
    @State private var selectedType: ContentType? = nil
    @State private var showStarredOnly = false
    @State private var showDetailEntry: ClipboardEntry? = nil
    @State private var showSettings = false

    var body: some View {
        VStack(spacing: 0) {
            // 顶部筛选栏
            FilterBar(
                searchText: $searchText,
                selectedType: $selectedType,
                showStarredOnly: $showStarredOnly
            )

            Divider()
                .padding(.top, 6)

            // 条目列表
            if filteredEntries.isEmpty {
                emptyView
            } else {
                ScrollView {
                    LazyVStack(spacing: 2) {
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
                                Button(entry.isPinned ? "取消置顶" : "置顶") {
                                    db.togglePin(entry)
                                }
                                Button(entry.isStarred ? "取消星标" : "星标") {
                                    db.toggleStar(entry)
                                }
                                Divider()
                                Button("查看详情") {
                                    showDetailEntry = entry
                                }
                                Button("删除", role: .destructive) {
                                    db.deleteEntry(entry)
                                }
                            }
                            .onTapGesture(count: 2) {
                                showDetailEntry = entry
                            }
                        }
                    }
                    .padding(.vertical, 6)
                }
            }

            Divider()

            // 底部栏
            bottomBar
        }
        .frame(width: 380)
        .frame(minHeight: 300, maxHeight: 520)
        .background(Color.white)
        .sheet(item: $showDetailEntry) { entry in
            EntryDetailView(entry: entry)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }

    // MARK: - Computed

    /// 当前筛选后的条目（搜索由DB层处理，这里做客户端二次过滤）
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

    // MARK: - Subviews

    var emptyView: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "clipboard")
                .font(.system(size: 36))
                .foregroundColor(.lightBlue)
            Text("暂无剪贴板历史")
                .font(.system(size: 14))
                .foregroundColor(.secondaryGray)
            Text("试试复制一些内容吧 ✨")
                .font(.system(size: 12))
                .foregroundColor(.lightBlue)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    var bottomBar: some View {
        HStack {
            Text("共 \(filteredEntries.count) 条")
                .font(.system(size: 11))
                .foregroundColor(.secondaryGray)

            Spacer()

            Button(action: { showSettings = true }) {
                HStack(spacing: 3) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 12))
                    Text("设置")
                        .font(.system(size: 11))
                }
                .foregroundColor(.secondaryGray)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    // MARK: - Actions

    private func refresh() {
        db.loadEntries()
    }

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
            // 同时复制路径字符串和文件 URL
            NSPasteboard.general.setString(entry.filePath, forType: .string)
            if let url = URL(string: "file://\(entry.filePath)") {
                NSPasteboard.general.writeObjects([url as NSURL])
            }
        }
    }
}
