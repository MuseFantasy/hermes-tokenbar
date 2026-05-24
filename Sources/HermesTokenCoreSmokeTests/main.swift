import Foundation
import HermesTokenCore
import SQLite3

@discardableResult
func expect(_ condition: @autoclosure () -> Bool, _ message: String) -> Bool {
    if !condition() {
        fputs("FAIL: \(message)\n", stderr)
        exit(1)
    }
    return true
}

func testAggregatesTodayMonthAndTopModelsFromHermesSessions() throws {
    let dbPath = try makeTempDatabase()
    let calendar = Calendar(identifier: .gregorian)
    let now = Date(timeIntervalSince1970: 1_764_000_000)
    let today = calendar.startOfDay(for: now).addingTimeInterval(3600)
    let yesterday = calendar.startOfDay(for: now).addingTimeInterval(-3600)
    let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!.addingTimeInterval(7200)
    let previousMonth = monthStart.addingTimeInterval(-172_800)

    try insertSession(dbPath: dbPath, id: "s1", model: "deepseek-v4-pro", startedAt: today.timeIntervalSince1970, input: 100, output: 20, cacheRead: 50, cacheWrite: 5, reasoning: 0)
    try insertSession(dbPath: dbPath, id: "s2", model: "deepseek-v4-flash", startedAt: today.timeIntervalSince1970 + 10, input: 10, output: 5, cacheRead: 0, cacheWrite: 0, reasoning: 2)
    try insertSession(dbPath: dbPath, id: "s3", model: "deepseek-v4-pro", startedAt: yesterday.timeIntervalSince1970, input: 200, output: 30, cacheRead: 70, cacheWrite: 0, reasoning: 0)
    try insertSession(dbPath: dbPath, id: "s4", model: "ark-code-latest", startedAt: monthStart.timeIntervalSince1970, input: 1, output: 2, cacheRead: 3, cacheWrite: 4, reasoning: 5)
    try insertSession(dbPath: dbPath, id: "s5", model: "old", startedAt: previousMonth.timeIntervalSince1970, input: 999, output: 999, cacheRead: 999, cacheWrite: 999, reasoning: 999)

    let stats = try HermesTokenStatsReader(databasePath: dbPath, now: now).read()

    expect(stats.today.totalTokens == 192, "today total should be 192, got \(stats.today.totalTokens)")
    expect(stats.today.llmInputTokens == 165, "today llm input should include input+cache read/write, got \(stats.today.llmInputTokens)")
    expect(stats.today.llmOutputTokens == 27, "today llm output should include output+reasoning, got \(stats.today.llmOutputTokens)")
    expect(stats.month.totalTokens == 507, "month total should be 507, got \(stats.month.totalTokens)")
    expect(stats.topModels.first?.model == "deepseek-v4-pro", "top model should be deepseek-v4-pro")
    expect(stats.topModels.first?.totalTokens == 475, "top model total should be 475")
    expect(stats.topModels.map(\.model) == ["deepseek-v4-pro", "deepseek-v4-flash", "ark-code-latest"], "top model order mismatch: \(stats.topModels.map(\.model))")
}

func testMissingDatabaseReturnsEmptyStatsInsteadOfThrowing() throws {
    let stats = try HermesTokenStatsReader(databasePath: "/tmp/definitely-missing-hermes-state.db", now: Date(timeIntervalSince1970: 1_764_000_000)).read()
    expect(stats.today.totalTokens == 0, "missing db today should be zero")
    expect(stats.month.totalTokens == 0, "missing db month should be zero")
    expect(stats.topModels.isEmpty, "missing db topModels should be empty")
}

func makeTempDatabase() throws -> String {
    let path = FileManager.default.temporaryDirectory
        .appendingPathComponent("HermesTokenStatsSmokeTests-\(UUID().uuidString).db")
        .path
    var db: OpaquePointer?
    guard sqlite3_open(path, &db) == SQLITE_OK else { throw TestError.sqlite("open failed") }
    defer { sqlite3_close(db) }
    let sql = """
    CREATE TABLE sessions (
        id TEXT PRIMARY KEY,
        model TEXT,
        started_at REAL NOT NULL,
        input_tokens INTEGER DEFAULT 0,
        output_tokens INTEGER DEFAULT 0,
        cache_read_tokens INTEGER DEFAULT 0,
        cache_write_tokens INTEGER DEFAULT 0,
        reasoning_tokens INTEGER DEFAULT 0
    );
    """
    guard sqlite3_exec(db, sql, nil, nil, nil) == SQLITE_OK else { throw TestError.sqlite("create table failed") }
    return path
}

func insertSession(dbPath: String, id: String, model: String, startedAt: Double, input: Int, output: Int, cacheRead: Int, cacheWrite: Int, reasoning: Int) throws {
    var db: OpaquePointer?
    guard sqlite3_open(dbPath, &db) == SQLITE_OK else { throw TestError.sqlite("open insert failed") }
    defer { sqlite3_close(db) }
    let sql = """
    INSERT INTO sessions (id, model, started_at, input_tokens, output_tokens, cache_read_tokens, cache_write_tokens, reasoning_tokens)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?);
    """
    var stmt: OpaquePointer?
    guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { throw TestError.sqlite("prepare insert failed") }
    defer { sqlite3_finalize(stmt) }
    let transient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
    sqlite3_bind_text(stmt, 1, id, -1, transient)
    sqlite3_bind_text(stmt, 2, model, -1, transient)
    sqlite3_bind_double(stmt, 3, startedAt)
    sqlite3_bind_int64(stmt, 4, sqlite3_int64(input))
    sqlite3_bind_int64(stmt, 5, sqlite3_int64(output))
    sqlite3_bind_int64(stmt, 6, sqlite3_int64(cacheRead))
    sqlite3_bind_int64(stmt, 7, sqlite3_int64(cacheWrite))
    sqlite3_bind_int64(stmt, 8, sqlite3_int64(reasoning))
    guard sqlite3_step(stmt) == SQLITE_DONE else { throw TestError.sqlite("insert step failed") }
}

enum TestError: Error {
    case sqlite(String)
}

try testAggregatesTodayMonthAndTopModelsFromHermesSessions()
try testMissingDatabaseReturnsEmptyStatsInsteadOfThrowing()
print("PASS: HermesTokenCoreSmokeTests")
