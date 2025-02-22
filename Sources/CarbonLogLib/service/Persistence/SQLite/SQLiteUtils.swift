import Foundation
import SQLite3

private extension String {
    var sqliteString: UnsafePointer<CChar>? { (self as NSString).utf8String }
}

public enum SQLiteStatus: Sendable, Equatable {
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

// TODO: https://www.kodeco.com/6620276-sqlite-with-swift-tutorial-getting-started?page=3#toc-anchor-014

struct SQLiteDB {
    fileprivate let dbPointer: OpaquePointer?

    private init(dbPointer: OpaquePointer) {
        self.dbPointer = dbPointer
    }

    func tableExists(tableName: String) throws -> Bool {
        let statementString = "SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='\(tableName)';"

        let tableExistsStatement: SQLiteStatement = try! prepareStament(statement: statementString)
        defer { tableExistsStatement.finalize() }

        tableExistsStatement.bind(text: tableName, atPos: 1)
        let execResult = tableExistsStatement.executeStep()
        guard execResult == .Done || execResult == .Row else {
            throw SQLError.SQLiteErrorWithStatus("Coulnt check if table \(tableName) exists", execResult)
        }

        let count = tableExistsStatement.getRowIntCell(atPos: 0)

        return count > 0
    }

    func prepareStament(statement: String) throws -> SQLiteStatement {
        var statementPointer: OpaquePointer?

        let prepareReturnCode = sqlite3_prepare_v2(dbPointer, statement, -1, &statementPointer, nil)
        guard prepareReturnCode == SQLITE_OK else {
            throw SQLError.SQLiteErrorWithStatus("Could not prepare statement: \(statement)", SQLiteStatus.of(prepareReturnCode))
        }

        return SQLiteStatement(backingPointer: statementPointer)
    }

    func executeStatement(statement: String) throws {
        let statementPointer: SQLiteStatement = try prepareStament(statement: statement)
        defer { statementPointer.finalize() }

        let executeReturnCode = statementPointer.executeStep()
        guard executeReturnCode == .Done else { throw SQLError.SQLiteErrorWithStatus("Could not execute statement: \(statement)", executeReturnCode) }
    }

    static func fromPath(filepath: String) throws -> SQLiteDB {
        var db: OpaquePointer?
        guard sqlite3_open(filepath, &db) == SQLITE_OK else { throw SQLError.CannotOpenDb }
        return SQLiteDB(dbPointer: db!)
    }
}
