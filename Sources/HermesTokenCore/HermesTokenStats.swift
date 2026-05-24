import Foundation
import SQLite3

public struct TokenBucket: Equatable, Sendable {
    public let inputTokens: Int64
    public let outputTokens: Int64
    public let cacheReadTokens: Int64
    public let cacheWriteTokens: Int64
    public let reasoningTokens: Int64

    public var totalTokens: Int64 {
        inputTokens + outputTokens + cacheReadTokens + cacheWriteTokens + reasoningTokens
    }

    public var llmInputTokens: Int64 {
        inputTokens + cacheReadTokens + cacheWriteTokens
    }

    public var llmOutputTokens: Int64 {
        outputTokens + reasoningTokens
    }

    public static let zero = TokenBucket(inputTokens: 0, outputTokens: 0, cacheReadTokens: 0, cacheWriteTokens: 0, reasoningTokens: 0)
}

public struct ModelTokenTotal: Equatable, Sendable {
    public let model: String
    public let totalTokens: Int64
}

public struct HermesTokenStats: Equatable, Sendable {
    public let today: TokenBucket
    public let month: TokenBucket
    public let topModels: [ModelTokenTotal]
    public let refreshedAt: Date
}

public final class HermesTokenStatsReader {
    private let databasePath: String
    private let now: Date
    private let calendar: Calendar

    public init(databasePath: String, now: Date = Date(), calendar: Calendar = Calendar(identifier: .gregorian)) {
        self.databasePath = databasePath
        self.now = now
        self.calendar = calendar
    }

    public func read() throws -> HermesTokenStats {
        guard FileManager.default.fileExists(atPath: databasePath) else {
            return HermesTokenStats(today: .zero, month: .zero, topModels: [], refreshedAt: now)
        }
        var db: OpaquePointer?
        guard sqlite3_open_v2(databasePath, &db, SQLITE_OPEN_READONLY, nil) == SQLITE_OK else {
            throw SQLiteError.open(message: String(cString: sqlite3_errmsg(db)))
        }
        defer { sqlite3_close(db) }

        let todayStart = calendar.startOfDay(for: now).timeIntervalSince1970
        let monthStartDate = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? calendar.startOfDay(for: now)
        let monthStart = monthStartDate.timeIntervalSince1970

        let today = try aggregate(db: db, since: todayStart)
        let month = try aggregate(db: db, since: monthStart)
        let topModels = try topModels(db: db, since: monthStart, limit: 5)
        return HermesTokenStats(today: today, month: month, topModels: topModels, refreshedAt: now)
    }

    private func aggregate(db: OpaquePointer?, since: TimeInterval) throws -> TokenBucket {
        let sql = """
        SELECT
            COALESCE(SUM(input_tokens), 0),
            COALESCE(SUM(output_tokens), 0),
            COALESCE(SUM(cache_read_tokens), 0),
            COALESCE(SUM(cache_write_tokens), 0),
            COALESCE(SUM(reasoning_tokens), 0)
        FROM sessions
        WHERE started_at >= ?;
        """
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw SQLiteError.prepare(message: String(cString: sqlite3_errmsg(db)))
        }
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_double(stmt, 1, since)
        guard sqlite3_step(stmt) == SQLITE_ROW else { return .zero }
        return TokenBucket(
            inputTokens: sqlite3_column_int64(stmt, 0),
            outputTokens: sqlite3_column_int64(stmt, 1),
            cacheReadTokens: sqlite3_column_int64(stmt, 2),
            cacheWriteTokens: sqlite3_column_int64(stmt, 3),
            reasoningTokens: sqlite3_column_int64(stmt, 4)
        )
    }

    private func topModels(db: OpaquePointer?, since: TimeInterval, limit: Int) throws -> [ModelTokenTotal] {
        let sql = """
        SELECT COALESCE(NULLIF(model, ''), 'unknown') AS model_name,
               COALESCE(SUM(input_tokens + output_tokens + cache_read_tokens + cache_write_tokens + reasoning_tokens), 0) AS total
        FROM sessions
        WHERE started_at >= ?
        GROUP BY model_name
        HAVING total > 0
        ORDER BY total DESC
        LIMIT ?;
        """
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw SQLiteError.prepare(message: String(cString: sqlite3_errmsg(db)))
        }
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_double(stmt, 1, since)
        sqlite3_bind_int(stmt, 2, Int32(limit))

        var rows: [ModelTokenTotal] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            let model = String(cString: sqlite3_column_text(stmt, 0))
            let total = sqlite3_column_int64(stmt, 1)
            rows.append(ModelTokenTotal(model: model, totalTokens: total))
        }
        return rows
    }
}

public enum SQLiteError: Error, CustomStringConvertible {
    case open(message: String)
    case prepare(message: String)

    public var description: String {
        switch self {
        case .open(let message): return "SQLite open failed: \(message)"
        case .prepare(let message): return "SQLite prepare failed: \(message)"
        }
    }
}

private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
