import AppKit
import SwiftUI

/// 历史粘贴板 - 入口

@main
struct HistoryClipboardApp: App {
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate

    init() {
        // 提前初始化数据库，避免 SwiftUI 视图初始化时首次访问导致崩溃
        _ = DatabaseManager.shared
    }

    var body: some Scene {
        Window("历史粘贴板", id: "main") {
            MainWindowView()
                .frame(minWidth: 420, minHeight: 520)
        }
        .defaultSize(width: 420, height: 600)
        .windowResizability(.contentSize)

        Settings {
            SettingsView()
        }
    }
}

// MARK: - AppDelegate

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("[AppDelegate] 启动服务...")
        ClipboardMonitor.shared.start()
        CleanupService.shared.start()
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationWillTerminate(_ notification: Notification) {
        ClipboardMonitor.shared.stop()
        CleanupService.shared.stop()
    }
}
