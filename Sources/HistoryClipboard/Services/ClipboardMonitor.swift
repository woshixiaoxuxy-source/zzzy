import AppKit
import Foundation

/// 剪贴板变化监控器
final class ClipboardMonitor {
    static let shared = ClipboardMonitor()

    private let pasteboard = NSPasteboard.general
    private var lastChangeCount: Int = 0
    private var timer: Timer?
    private var isRunning = false

    /// 轮询间隔（秒）
    private let pollInterval: TimeInterval = 0.5

    /// 文件大小限制：500MB
    private let maxFileSize: Int64 = 500 * 1024 * 1024

    private init() {}

    // MARK: - Start / Stop

    func start() {
        guard !isRunning else { return }
        isRunning = true
        lastChangeCount = pasteboard.changeCount

        timer = Timer.scheduledTimer(withTimeInterval: pollInterval, repeats: true) { [weak self] _ in
            self?.checkForChanges()
        }

        // 允许 timer 在 runloop 常用模式下运行
        if let timer = timer {
            RunLoop.current.add(timer, forMode: .common)
        }

        print("[Monitor] Started")
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        print("[Monitor] Stopped")
    }

    // MARK: - Detection

    private func checkForChanges() {
        let currentCount = pasteboard.changeCount
        guard currentCount != lastChangeCount else { return }

        lastChangeCount = currentCount
        processPasteboardContent()
    }

    private func processPasteboardContent() {
        let types = pasteboard.types ?? []

        // 获取来源应用
        var sourceApp = ""
        if let app = NSWorkspace.shared.frontmostApplication {
            sourceApp = app.localizedName ?? "Unknown"
        }

        // 检测内容类型并处理
        if types.contains(.fileURL), let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL], let firstURL = urls.first {
            // 文件类型
            processFileURL(firstURL, sourceApp: sourceApp)
        } else if types.contains(.tiff), let image = NSImage(pasteboard: pasteboard) {
            // 图片类型
            processImage(image, sourceApp: sourceApp)
        } else if types.contains(.string), let text = pasteboard.string(forType: .string) {
            // 文本类型
            processText(text, sourceApp: sourceApp)
        }
    }

    // MARK: - Processors

    private func processText(_ text: String, sourceApp: String) {
        let contentType: ContentType = text.isURL ? .url : .text
        let sizeBytes = Int64(text.utf8.count)

        DatabaseManager.shared.insertEntry(
            contentType: contentType,
            textContent: text,
            sourceApp: sourceApp,
            sizeBytes: sizeBytes
        )
    }

    private func processImage(_ image: NSImage, sourceApp: String) {
        guard let tiffData = image.tiffRepresentation else { return }
        let bitmap = NSBitmapImageRep(data: tiffData)
        let imageData = bitmap?.representation(using: .png, properties: [:])

        guard let data = imageData else { return }

        // 检查大小
        guard Int64(data.count) <= maxFileSize else {
            print("[Monitor] Skipping image: size \(data.count) > 500MB")
            return
        }

        DatabaseManager.shared.insertEntry(
            contentType: .image,
            textContent: "",
            imageData: data,
            sourceApp: sourceApp,
            sizeBytes: Int64(data.count)
        )
    }

    private func processFileURL(_ url: URL, sourceApp: String) {
        let filePath = url.path

        // 获取文件大小
        let fileSize: Int64
        do {
            let attrs = try FileManager.default.attributesOfItem(atPath: filePath)
            fileSize = (attrs[.size] as? Int64) ?? 0
        } catch {
            fileSize = 0
        }

        // 跳过超过 500MB 的文件
        guard fileSize <= maxFileSize else {
            print("[Monitor] Skipping file: size \(fileSize) > 500MB")
            return
        }

        DatabaseManager.shared.insertEntry(
            contentType: .file,
            textContent: filePath,
            filePath: filePath,
            sourceApp: sourceApp,
            sizeBytes: fileSize
        )
    }
}
