import Foundation

/// 自动清理过期条目的服务
final class CleanupService {
    static let shared = CleanupService()

    private var timer: Timer?
    /// 每小时清理一次
    private let cleanupInterval: TimeInterval = 3600

    private init() {}

    func start() {
        // 启动时立即执行一次
        performCleanup()

        timer = Timer.scheduledTimer(withTimeInterval: cleanupInterval, repeats: true) { [weak self] _ in
            self?.performCleanup()
        }
        if let timer = timer {
            RunLoop.current.add(timer, forMode: .common)
        }
        print("[Cleanup] Started")
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func performCleanup() {
        let days = DatabaseManager.shared.retentionDays
        print("[Cleanup] Removing entries older than \(days) days")
        DatabaseManager.shared.cleanupOlderThan(days: days)
    }
}
