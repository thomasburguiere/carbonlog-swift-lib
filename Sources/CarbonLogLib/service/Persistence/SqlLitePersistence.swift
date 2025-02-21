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
        let insertStatement: SQLiteStatement = try db.prepareStament(statement: insertStatementString)

        let id = id ?? UUID().uuidString
        let carbonKg = measurement.carbonKg
        let dateString = formatter.string(from: measurement.date)
        // 2
        insertStatement.bind(text: id, atPos: 1)
        insertStatement.bind(double: carbonKg, pos: 2)
        insertStatement.bind(text: dateString, atPos: 3)
        if let comment = measurement.comment {
            insertStatement.bind(text: comment, atPos: 4)
        }
        // 4
        if insertStatement.executeStep() == SQLITE_DONE {
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
        let selectStatement: SQLiteStatement = try db.prepareStament(statement: selectStatementString)

        selectStatement.bind(text: id, atPos: 1)
        guard selectStatement.executeStep() == SQLITE_ROW else { return nil }

        let date: Date? = formatter.date(from: selectStatement.getRowTextCell(atPos: 0))
        let carbonKg: Double? = selectStatement.getRowDoubleCell(atPos: 1)
        let comment: String? = selectStatement.getRowTextCell(atPos: 2)

        guard let date, let carbonKg else { throw SQLError.InconsistentRow }

        return CarbonMeasurement(kg: carbonKg, at: date, comment: comment)
    }

    public func append(measurement _: CarbonMeasurement, toLogWithId _: String) async throws {}

    func createMeasurementTable() throws {
        let tableName = CarbonMeasurement.sqlTableName
        if try db.tableExists(tableName: tableName) { throw SQLError.DuplicateTable(tableName) }

        try db.executeStatement(statement: CarbonMeasurement.sqlTableString)
    }
}

/// SQLite stuff below

private extension String {
    var sqliteString: UnsafePointer<CChar>? { (self as NSString).utf8String }
}

struct SQLiteStatement {
    let backingPointer: OpaquePointer?

    func bind(text: String, atPos: Int32) {
        sqlite3_bind_text(backingPointer, atPos, text.sqliteString, -1, nil)
    }

    func bind(double: Double, pos: Int32) {
        sqlite3_bind_double(backingPointer, pos, double)
    }

    func executeStep() -> Int32 {
        return sqlite3_step(backingPointer)
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

        tableExistsStatement.bind(text: tableName, atPos: 1)
        let execResult = tableExistsStatement.executeStep()
        guard execResult == SQLITE_DONE || execResult == SQLITE_ROW else {
            throw SQLError.SQLiteErrorWithCode("Coulnt check if table \(tableName) exists", execResult)
        }

        let count = tableExistsStatement.getRowIntCell(atPos: 0)

        return count > 0
    }

    func prepareStament(statement: String) throws -> SQLiteStatement {
        var statementPointer: OpaquePointer?

        let prepareReturnCode = sqlite3_prepare_v2(dbPointer, statement, -1, &statementPointer, nil)
        guard prepareReturnCode == SQLITE_OK else {
            throw SQLError.SQLiteErrorWithCode("Could not prepare statement: \(statement)", prepareReturnCode)
        }

        return SQLiteStatement(backingPointer: statementPointer)
    }

    func executeStatement(statement: String) throws {
        let statementPointer: SQLiteStatement = try prepareStament(statement: statement)
        defer {
            statementPointer.finalize()
        }

        let executeReturnCode = statementPointer.executeStep()
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
