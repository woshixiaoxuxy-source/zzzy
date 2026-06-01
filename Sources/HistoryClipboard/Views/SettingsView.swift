import SwiftUI
import ServiceManagement

/// 设置视图
struct SettingsView: View {
    @ObservedObject private var db = DatabaseManager.shared
    @State private var selectedDays: Int = 7
    @State private var customDays: String = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var launchAtLogin: Bool = false

    let presets = [1, 3, 7, 14, 30]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Image(systemName: "gearshape")
                    .font(.title2)
                    .foregroundColor(.accentBlue)
                Text("设置")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.black)
            }

            Divider()

            // 开机自启
            VStack(alignment: .leading, spacing: 8) {
                Text("🚀 启动")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.black)
                Toggle(isOn: $launchAtLogin) {
                    Text("开机自动启动")
                        .font(.system(size: 14))
                        .foregroundColor(.black)
                }
                .toggleStyle(.switch)
                .onChange(of: launchAtLogin) { newValue in
                    toggleLaunchAtLogin(newValue)
                }
            }

            Divider()

            // 存储期限
            VStack(alignment: .leading, spacing: 12) {
                Text("📅 存储期限")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.black)

                Text("超过期限的条目将被自动删除（置顶和星标条目不会被删除）")
                    .font(.system(size: 12))
                    .foregroundColor(.secondaryGray)

                HStack(spacing: 8) {
                    ForEach(presets, id: \.self) { days in
                        presetButton(days)
                    }
                }

                HStack(spacing: 6) {
                    Text("自定义：")
                        .font(.system(size: 13))
                        .foregroundColor(.black)
                    TextField("天数", text: $customDays)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 60)
                        .font(.system(size: 13))
                    Text("天")
                        .font(.system(size: 13))
                        .foregroundColor(.black)
                    Button("应用") {
                        if let days = Int(customDays), days > 0 {
                            selectedDays = days
                            applyRetention(days)
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .tint(Color.accentBlue)
                    .disabled(customDays.isEmpty)
                }
            }

            Divider()

            // 数据管理
            VStack(alignment: .leading, spacing: 10) {
                Text("⚠️ 数据管理")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.orange)

                HStack(spacing: 10) {
                    Button("立即清理过期条目") {
                        CleanupService.shared.performCleanup()
                        alertMessage = "已清理过期条目"
                        showAlert = true
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .tint(.orange)

                    Button("删除所有非置顶/星标条目") {
                        DatabaseManager.shared.deleteAll()
                        alertMessage = "已删除所有非置顶/星标条目"
                        showAlert = true
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .tint(.red)
                }
            }

            Spacer()

            HStack {
                Text("数据库：~/Library/Application Support/HistoryClipboard/")
                    .font(.system(size: 10))
                    .foregroundColor(.secondaryGray)
            }
        }
        .padding(24)
        .frame(width: 460, height: 450)
        .onAppear {
            selectedDays = DatabaseManager.shared.retentionDays
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
        .alert("提示", isPresented: $showAlert) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }

    private func toggleLaunchAtLogin(_ enable: Bool) {
        do {
            if enable {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            alertMessage = enable ? "开机自启设置失败：\(error.localizedDescription)" : "取消开机自启失败"
            showAlert = true
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }

    private func presetButton(_ days: Int) -> some View {
        Button(action: {
            selectedDays = days
            applyRetention(days)
        }) {
            Text("\(days) 天")
                .font(.system(size: 13, weight: selectedDays == days ? .semibold : .medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(selectedDays == days ? Color.accentBlue : Color(white: 0.88))
                .foregroundColor(selectedDays == days ? .white : Color(white: 0.2))
                .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }

    private func applyRetention(_ days: Int) {
        DatabaseManager.shared.setRetentionDays(days)
        CleanupService.shared.performCleanup()
    }
}
