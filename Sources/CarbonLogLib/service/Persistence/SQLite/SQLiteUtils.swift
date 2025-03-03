import Foundation
import SQLite3

private extension String {
    var sqliteString: UnsafePointer<CChar>? { (self as NSString).utf8String }
}

enum SQLiteStatus: Sendable, Equatable {
    case Done
    case Row
    case GeneralError
    case Constraint
    case Unknown(Int)

    static func of(_ i32: Int32) -> SQLiteStatus {
        switch i32 {
        case SQLITE_DONE: return .Done
        case SQLITE_ROW: return .Row
        case SQLITE_ERROR: return .GeneralError
        case SQLITE_CONSTRAINT: return .Constraint
        default: return .Unknown(Int(i32))
        }
    }
}

struct SQLiteStatement {
    let backingPointer: OpaquePointer?

    func bind(text: String, atPos: Int32) {
        sqlite3_bind_text(backingPointer, atPos, text.sqliteString, -1, nil)
    }

    func bind(double: Double, atPos: Int32) {
        sqlite3_bind_double(backingPointer, atPos, double)
    }

    func executeStep() -> SQLiteStatus {
        return SQLiteStatus.of(sqlite3_step(backingPointer))
    }

    func getRowIntCell(atPos pos: Int32) -> Int {
        return Int(sqlite3_column_int(backingPointer, pos))
    }

    func getRowDoubleCell(atPos pos: Int32) -> Double {
        return sqlite3_column_double(backingPointer, pos)
    }

    func getRowTextCell(atPos pos: Int32) -> String {
        return String(cString: sqlite3_column_text(backingPointer, pos))
    }

    func finalize() {
        sqlite3_finalize(backingPointer)
    }
}

// https://www.kodeco.com/6620276-sqlite-with-swift-tutorial-getting-started?page=3#toc-anchor-014

struct SQLiteDB {
    fileprivate let dbPointer: OpaquePointer?

    private init(dbPointer: OpaquePointer) {
        self.dbPointer = dbPointer
        do { try enableFkSupport() } catch {}
    }

    func createTable(_ tableName: String, withCreateQuery query: String) throws {
        if try tableExists(tableName: tableName) { throw SQLError.DuplicateTable(tableName) }

        try executeStatement(statement: query)
    }

    func createTableIfNotExist(_ tableName: String, withCreateQuery query: String) throws {
        let exists = (try? tableExists(tableName: tableName)) ?? false
        if !exists {
            try createTable(tableName, withCreateQuery: query)
        }
    }

    func tableExists(tableName: String) throws -> Bool {
        let query =
            "SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name= ?;"

        let statement: SQLiteStatement = try! prepareStament(statement: query)
        defer { statement.finalize() }

        statement.bind(text: tableName, atPos: 1)

        let status = statement.executeStep()
        guard status == .Done || status == .Row else {
            throw SQLError.SQLiteErrorWithStatus(
                "Coulnt check if table \(tableName) exists",
                status
            )
        }

        let count = statement.getRowIntCell(atPos: 0)

        return count > 0
    }

    func prepareStament(statement: String) throws -> SQLiteStatement {
        var statementPointer: OpaquePointer?

        let prepareReturnCode = sqlite3_prepare_v2(dbPointer, statement, -1, &statementPointer, nil)
        guard prepareReturnCode == SQLITE_OK else {
            throw SQLError.SQLiteErrorWithStatus(
                "Could not prepare statement: \(statement)",
                SQLiteStatus.of(prepareReturnCode)
            )
        }

        return SQLiteStatement(backingPointer: statementPointer)
    }

    static func fromPath(filepath: String) throws -> SQLiteDB {
        var db: OpaquePointer?
        guard sqlite3_open(filepath, &db) == SQLITE_OK else {
            throw SQLError.CannotOpenDb(filepath)
        }
        return SQLiteDB(dbPointer: db!)
    }

    private func executeStatement(statement: String) throws {
        let statementPointer: SQLiteStatement = try prepareStament(statement: statement)
        defer { statementPointer.finalize() }

        let executeReturnCode = statementPointer.executeStep()
        guard executeReturnCode == .Done else {
            throw SQLError.SQLiteErrorWithStatus(
                "Could not execute statement: \(statement)",
                executeReturnCode
            )
        }
    }

    private func enableFkSupport() throws {
        let query = "PRAGMA foreign_keys = ON;"
        try executeStatement(statement: query)
    }
}
