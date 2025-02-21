import Foundation
import SQLite3

public enum SQLError: Error, Equatable {
    case CouldNotPrepareStatement
    case InconsistentRow
    case CannotOpenDb
    case DuplicateTable(String)
    case SQLiteErrorWithCode(String, Int32)
}

public struct SQLitePersistenceService: CarbonLogPersistenceService {
    let formatter = ISO8601DateFormatter()
    let dbFilePath: URL
    let db: SQLiteDB

    init(dbPath: URL) throws {
        dbFilePath = dbPath
        db = try SQLiteDB.fromPath(filepath: dbPath.absoluteString)
    }

    public func persist(log _: CarbonLog) async throws {}

    public func persist(measurement: CarbonMeasurement, id: String? = nil) async throws {
        var insertStatement: OpaquePointer?
        let insertStatementString = """
          INSERT INTO CarbonMeasurement (id, carbonKg, date, comment) VALUES (?, ?, ?, ?);
        """

        let prepareStatementResult = sqlite3_prepare_v2(db.dbPointer, insertStatementString, -1, &insertStatement, nil)
        guard prepareStatementResult == SQLITE_OK else {
            throw SQLError.CouldNotPrepareStatement
        }
        let id: NSString = (id ?? UUID().uuidString) as NSString
        let carbonKg = measurement.carbonKg
        let date: NSString = formatter.string(from: measurement.date) as NSString
        // 2
        sqlite3_bind_text(insertStatement, 1, id.utf8String, -1, nil)
        sqlite3_bind_double(insertStatement, 2, carbonKg)
        sqlite3_bind_text(insertStatement, 3, date.utf8String, -1, nil)
        if let comment = measurement.comment {
            let comment: NSString = comment as NSString
            sqlite3_bind_text(insertStatement, 4, comment.utf8String, -1, nil)
        }
        // 4
        if sqlite3_step(insertStatement) == SQLITE_DONE {
            print("\nSuccessfully inserted row.")
        } else {
            print("\nCould not insert row.")
        }
    }

    public func load(id _: String) async -> CarbonLog? {
        return nil
    }

    public func load(measurementId id: String) throws -> CarbonMeasurement? {
        let db = try SQLiteDB.fromPath(filepath: dbFilePath.absoluteString)
        var selectStatement: OpaquePointer?
        let selectStatementString = """
          select date, carbonKg, comment from CarbonMeasurement where id = ?;
        """
        guard sqlite3_prepare_v2(db.dbPointer, selectStatementString, -1, &selectStatement, nil) == SQLITE_OK else {
            throw SQLError.CouldNotPrepareStatement
        }

        let nsId: NSString = id as NSString

        sqlite3_bind_text(selectStatement, 1, nsId.utf8String, -1, nil)
        guard sqlite3_step(selectStatement) == SQLITE_ROW else { return nil }

        let date: Date? = sqlite3_column_text(selectStatement, 0)
            .flatMap { formatter.date(from: String(cString: $0)) }
        let carbonKg: Double? = sqlite3_column_double(selectStatement, 1)
        let comment: String? = sqlite3_column_text(selectStatement, 2)
            .flatMap { String(cString: $0) }

        guard let date, let carbonKg else { throw SQLError.InconsistentRow }

        return CarbonMeasurement(kg: carbonKg, at: date, comment: comment)
    }

    public func append(measurement _: CarbonMeasurement, toLogWithId _: String) async throws {}

    func createMeasurementTable() throws {
        let tableName = "CarbonMeasurement"
        if db.tableExists(tableName: tableName) { throw SQLError.DuplicateTable(tableName)
        }
        let createTableString = """
          CREATE TABLE "\(tableName)" (
            "id"	TEXT NOT NULL UNIQUE,
            "carbonKg"	NUMERIC NOT NULL,
            "date"	TEXT NOT NULL,
            "comment"	TEXT,
            PRIMARY KEY("id")
          );
        """
        try db.executeStatement(statement: createTableString)
    }
}

// TODO: https://www.kodeco.com/6620276-sqlite-with-swift-tutorial-getting-started?page=3#toc-anchor-014
struct SQLiteDB {
    fileprivate let dbPointer: OpaquePointer?

    private init(dbPointer: OpaquePointer) {
        self.dbPointer = dbPointer
    }

    func tableExists(tableName: String) -> Bool {
        let statementString = "SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='\(tableName)';"
        var stmtPointer: OpaquePointer?

        sqlite3_prepare(dbPointer, statementString, -1, &stmtPointer, nil)
        sqlite3_bind_text(stmtPointer, 1, (tableName as NSString).utf8String, -1, nil)
        sqlite3_step(stmtPointer)

        let count = sqlite3_column_int(stmtPointer, 0)

        return count > 0
    }

    func executeStatement(statement: String) throws {
        var statementPointer: OpaquePointer?

        let prepareReturnCode = sqlite3_prepare_v2(dbPointer, statement, -1, &statementPointer, nil)
        guard prepareReturnCode == SQLITE_OK else { throw SQLError.SQLiteErrorWithCode("Could not prepare statement: \(statement)", prepareReturnCode) }

        let executeReturnCode = sqlite3_step(statementPointer)
        guard executeReturnCode == SQLITE_DONE else { throw SQLError.SQLiteErrorWithCode("Could not execute statement: \(statement)", executeReturnCode) }

        sqlite3_finalize(statementPointer)
    }

    static func fromPath(filepath: String) throws -> SQLiteDB {
        var db: OpaquePointer?
        guard sqlite3_open(filepath, &db) == SQLITE_OK else { throw SQLError.CannotOpenDb }
        return SQLiteDB(dbPointer: db!)
    }

    //  deinit {
    //      sqlite3_close(self.dbPointer)
    //  }
}
