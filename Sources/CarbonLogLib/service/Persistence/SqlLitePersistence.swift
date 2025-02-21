import Foundation
import SQLite3

public enum SQLError: Error, Equatable {
    case CouldNotPrepareStatement
    case InconsistentRow
    case CannotOpenDb
    case DuplicateTable(String)
    case SQLiteErrorWithCode(String, Int32)
}

private extension CarbonMeasurement {
    static var sqlTableName: String { "CarbonMeasurement" }
    static var sqlTableString: String { """
      CREATE TABLE "\(sqlTableName)" (
        "id"    TEXT NOT NULL UNIQUE,
        "carbonKg"    NUMERIC NOT NULL,
        "date"    TEXT NOT NULL,
        "comment"    TEXT,
        PRIMARY KEY("id")
      );
    """
    }
}

private extension String {
    var sqliteString: UnsafePointer<CChar>? { (self as NSString).utf8String }
}

public struct SQLitePersistenceService: CarbonLogPersistenceService {
    let formatter = ISO8601DateFormatter()
    let db: SQLiteDB

    init(dbPath: URL) throws {
        db = try SQLiteDB.fromPath(filepath: dbPath.absoluteString)
    }

    public func persist(log _: CarbonLog) async throws {}

    public func persist(measurement: CarbonMeasurement, id: String? = nil) async throws {
        let insertStatementString = """
          INSERT INTO CarbonMeasurement (id, carbonKg, date, comment) VALUES (?, ?, ?, ?);
        """
        let insertStatement: OpaquePointer? = try db.prepareStament(statement: insertStatementString)

        let id = id ?? UUID().uuidString
        let carbonKg = measurement.carbonKg
        let dateString = formatter.string(from: measurement.date)
        // 2
        sqlite3_bind_text(insertStatement, 1, id.sqliteString, -1, nil)
        sqlite3_bind_double(insertStatement, 2, carbonKg)
        sqlite3_bind_text(insertStatement, 3, dateString.sqliteString, -1, nil)
        if let comment = measurement.comment {
            sqlite3_bind_text(insertStatement, 4, comment.sqliteString, -1, nil)
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
        let selectStatementString = """
          select date, carbonKg, comment from CarbonMeasurement where id = ?;
        """
        let selectStatement: OpaquePointer? = try db.prepareStament(statement: selectStatementString)

        sqlite3_bind_text(selectStatement, 1, id.sqliteString, -1, nil)
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
        let tableName = CarbonMeasurement.sqlTableName
        if db.tableExists(tableName: tableName) { throw SQLError.DuplicateTable(tableName) }

        try db.executeStatement(statement: CarbonMeasurement.sqlTableString)
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

        let tableExistsPointer: OpaquePointer? = try! prepareStament(statement: statementString)
        sqlite3_bind_text(tableExistsPointer, 1, tableName.sqliteString, -1, nil)
        sqlite3_step(tableExistsPointer)

        let count = sqlite3_column_int(tableExistsPointer, 0)

        return count > 0
    }

    func prepareStament(statement: String) throws -> OpaquePointer? {
        var statementPointer: OpaquePointer?

        let prepareReturnCode = sqlite3_prepare_v2(dbPointer, statement, -1, &statementPointer, nil)
        guard prepareReturnCode == SQLITE_OK else {
            throw SQLError.SQLiteErrorWithCode("Could not prepare statement: \(statement)", prepareReturnCode)
        }

        return statementPointer
    }

    func executeStatement(statement: String) throws {
        let statementPointer = try prepareStament(statement: statement)
        defer {
            sqlite3_finalize(statementPointer)
        }

        let executeReturnCode = sqlite3_step(statementPointer)
        guard executeReturnCode == SQLITE_DONE else { throw SQLError.SQLiteErrorWithCode("Could not execute statement: \(statement)", executeReturnCode) }
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
