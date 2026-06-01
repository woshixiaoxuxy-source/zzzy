import Foundation
import SQLite3

/// SQLITE_TRANSIENT 的 Swift 等价常量
private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

/// SQLite 数据库管理器 - 单例
/// 所有数据库操作均在 dbQueue 串行队列执行，保证线程安全
final class DatabaseManager: ObservableObject {
    static let shared = DatabaseManager()

    private var db: OpaquePointer?
    private let dbQueue = DispatchQueue(label: "com.historyclipboard.db", qos: .userInitiated)

    @Published var entries: [ClipboardEntry] = []
    @Published var totalCount: Int = 0

    private init() {
        // 初始化数据库（在 init 中同步完成，因为还没有其他操作）
        dbQueue.sync {
            self._openDatabase()
            self._createTables()
            self._applyDefaultSettings()
        }
        // 加载条目可以异步
        loadEntries()
    }

    deinit {
        dbQueue.sync {
            if let db = self.db {
                sqlite3_close(db)
                self.db = nil
            }
        }
    }

    // MARK: - Database Setup (called inside dbQueue)

    private func _openDatabase() {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        ).first!

        let appDir = appSupport.appendingPathComponent("HistoryClipboard")
        try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)

        let dbPath = appDir.appendingPathComponent("clipboard.db").path
        print("[DB] Path: \(dbPath)")

        if sqlite3_open(dbPath, &db) != SQLITE_OK {
            let err = String(cString: sqlite3_errmsg(db))
            print("[DB] Failed to open: \(err)")
            db = nil
            return
        }

        // 启用 WAL 模式
        _execute("PRAGMA journal_mode=WAL")
        _execute("PRAGMA synchronous=NORMAL")
        print("[DB] Opened successfully")
    }

    private func _createTables() {
        _execute("""
            CREATE TABLE IF NOT EXISTS clipboard_entries (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                content_type TEXT NOT NULL,
                text_content TEXT DEFAULT '',
                image_blob BLOB,
                file_path TEXT DEFAULT '',
                source_app TEXT DEFAULT '',
                size_bytes INTEGER DEFAULT 0,
                is_pinned INTEGER DEFAULT 0,
                is_starred INTEGER DEFAULT 0,
                created_at INTEGER NOT NULL
            );
        """)
        _execute("""
            CREATE TABLE IF NOT EXISTS settings (
                key TEXT PRIMARY KEY,
                value TEXT NOT NULL
            );
        """)
        _execute("CREATE INDEX IF NOT EXISTS idx_created_at ON clipboard_entries(created_at DESC);")
    }

    private func _applyDefaultSettings() {
        if _getSetting("retention_days") == nil {
            _setSetting("retention_days", value: "7")
        }
    }

    // MARK: - Execute (must be called within dbQueue)

    @discardableResult
    private func _execute(_ sql: String, _ bind: ((OpaquePointer) -> Void)? = nil) -> Bool {
        guard db != nil else { return false }
        var statement: OpaquePointer?
        defer { if let s = statement { sqlite3_finalize(s) } }

        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            print("[DB] Prepare error: \(String(cString: sqlite3_errmsg(db)))")
            return false
        }

        bind?(statement!)

        let rc = sqlite3_step(statement!)
        return rc == SQLITE_DONE || rc == SQLITE_ROW
    }

    private func _query(_ sql: String, _ bind: ((OpaquePointer) -> Void)? = nil) -> [ClipboardEntry] {
        guard db != nil else { return [] }
        var statement: OpaquePointer?
        defer { if let s = statement { sqlite3_finalize(s) } }

        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            print("[DB] Query prepare error: \(String(cString: sqlite3_errmsg(db)))")
            return []
        }

        bind?(statement!)

        var results: [ClipboardEntry] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            if let entry = _mapRow(statement!) {
                results.append(entry)
            }
        }
        return results
    }

    private func _mapRow(_ stmt: OpaquePointer) -> ClipboardEntry? {
        let id = sqlite3_column_int64(stmt, 0)
        let typeStr = String(cString: sqlite3_column_text(stmt, 1))
        let contentType = ContentType.fromDB(typeStr)

        let textContent = sqlite3_column_text(stmt, 2).map { String(cString: $0) } ?? ""

        let imageData: Data?
        if let blobPtr = sqlite3_column_blob(stmt, 3) {
            imageData = Data(bytes: blobPtr, count: Int(sqlite3_column_bytes(stmt, 3)))
        } else {
            imageData = nil
        }

        let filePath = sqlite3_column_text(stmt, 4).map { String(cString: $0) } ?? ""
        let sourceApp = sqlite3_column_text(stmt, 5).map { String(cString: $0) } ?? ""
        let sizeBytes = sqlite3_column_int64(stmt, 6)
        let isPinned = sqlite3_column_int(stmt, 7) != 0
        let isStarred = sqlite3_column_int(stmt, 8) != 0
        let createdAt = Date(timeIntervalSince1970: Double(sqlite3_column_int64(stmt, 9)))

        return ClipboardEntry(
            id: id,
            contentType: contentType,
            textContent: textContent,
            imageData: imageData,
            filePath: filePath,
            sourceApp: sourceApp,
            sizeBytes: sizeBytes,
            isPinned: isPinned,
            isStarred: isStarred,
            createdAt: createdAt
        )
    }

    // MARK: - Settings (thread-safe, uses dbQueue.sync)

    private func _getSetting(_ key: String) -> String? {
        guard db != nil else { return nil }
        var result: String?
        var statement: OpaquePointer?
        defer { if let s = statement { sqlite3_finalize(s) } }

        let sql = "SELECT value FROM settings WHERE key = ?;"
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else { return nil }
        sqlite3_bind_text(statement, 1, (key as NSString).utf8String, -1, nil)

        if sqlite3_step(statement) == SQLITE_ROW {
            result = String(cString: sqlite3_column_text(statement, 0))
        }
        return result
    }

    private func _setSetting(_ key: String, value: String) {
        _execute("INSERT OR REPLACE INTO settings (key, value) VALUES (?, ?);") { stmt in
            sqlite3_bind_text(stmt, 1, (key as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 2, (value as NSString).utf8String, -1, nil)
        }
    }

    // MARK: - Public API (thread-safe)

    func getSetting(_ key: String) -> String? {
        dbQueue.sync { self._getSetting(key) }
    }

    func setSetting(_ key: String, value: String) {
        dbQueue.sync { self._setSetting(key, value: value) }
    }

    var retentionDays: Int {
        Int(getSetting("retention_days") ?? "7") ?? 7
    }

    func setRetentionDays(_ days: Int) {
        dbQueue.sync { self._setSetting("retention_days", value: String(days)) }
    }

    // MARK: - Insert

    func insertEntry(
        contentType: ContentType,
        textContent: String,
        imageData: Data? = nil,
        filePath: String = "",
        sourceApp: String = "",
        sizeBytes: Int64 = 0
    ) {
        dbQueue.async { [weak self] in
            guard let self = self else { return }
            self._insert(
                contentType: contentType,
                textContent: textContent,
                imageData: imageData,
                filePath: filePath,
                sourceApp: sourceApp,
                sizeBytes: sizeBytes
            )
        }
    }

    private func _insert(
        contentType: ContentType,
        textContent: String,
        imageData: Data?,
        filePath: String,
        sourceApp: String,
        sizeBytes: Int64
    ) {
        // 去重
        if let last = _getLatest() {
            if last.contentType == contentType,
               last.textContent == textContent,
               last.filePath == filePath {
                return
            }
        }

        let now = Int64(Date().timeIntervalSince1970)
        _execute("""
            INSERT INTO clipboard_entries
            (content_type, text_content, image_blob, file_path, source_app, size_bytes, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?);
        """) { stmt in
            sqlite3_bind_text(stmt, 1, (contentType.dbValue as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 2, (textContent as NSString).utf8String, -1, nil)
            if let data = imageData {
                _ = data.withUnsafeBytes { ptr in
                    sqlite3_bind_blob(stmt, 3, ptr.baseAddress, Int32(data.count), SQLITE_TRANSIENT)
                }
            } else {
                sqlite3_bind_null(stmt, 3)
            }
            sqlite3_bind_text(stmt, 4, (filePath as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 5, (sourceApp as NSString).utf8String, -1, nil)
            sqlite3_bind_int64(stmt, 6, sizeBytes)
            sqlite3_bind_int64(stmt, 7, now)
        }

        DispatchQueue.main.async { [weak self] in
            self?.loadEntries()
        }
    }

    // MARK: - Query

    private func _getLatest() -> ClipboardEntry? {
        _query("SELECT * FROM clipboard_entries ORDER BY id DESC LIMIT 1;").first
    }

    func loadEntries() {
        dbQueue.async { [weak self] in
            guard let self = self else { return }
            let results = self._query(
                "SELECT * FROM clipboard_entries ORDER BY is_pinned DESC, created_at DESC LIMIT 500;"
            )
            DispatchQueue.main.async {
                self.entries = results
                self.totalCount = results.count
            }
        }
    }

    // MARK: - Update

    func togglePin(_ entry: ClipboardEntry) {
        dbQueue.async { [weak self] in
            let v = entry.isPinned ? 0 : 1
            self?._execute("UPDATE clipboard_entries SET is_pinned = \(v) WHERE id = \(entry.id);")
            DispatchQueue.main.async { self?.loadEntries() }
        }
    }

    func toggleStar(_ entry: ClipboardEntry) {
        dbQueue.async { [weak self] in
            let v = entry.isStarred ? 0 : 1
            self?._execute("UPDATE clipboard_entries SET is_starred = \(v) WHERE id = \(entry.id);")
            DispatchQueue.main.async { self?.loadEntries() }
        }
    }

    // MARK: - Delete

    func deleteEntry(_ entry: ClipboardEntry) {
        dbQueue.async { [weak self] in
            self?._execute("DELETE FROM clipboard_entries WHERE id = \(entry.id);")
            DispatchQueue.main.async { self?.loadEntries() }
        }
    }

    func cleanupOlderThan(days: Int) {
        dbQueue.async { [weak self] in
            let cutoff = Int64(Date().timeIntervalSince1970) - Int64(days * 86400)
            self?._execute("DELETE FROM clipboard_entries WHERE created_at < \(cutoff) AND is_pinned = 0 AND is_starred = 0;")
            DispatchQueue.main.async { self?.loadEntries() }
        }
    }

    func deleteAll() {
        dbQueue.async { [weak self] in
            self?._execute("DELETE FROM clipboard_entries WHERE is_pinned = 0 AND is_starred = 0;")
            DispatchQueue.main.async { self?.loadEntries() }
        }
    }
}
