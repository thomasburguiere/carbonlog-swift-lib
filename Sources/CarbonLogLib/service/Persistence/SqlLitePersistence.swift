import Foundation
import SQLite3

public enum SQLError: Error {
    case CouldNotPrepareStatement
    case InconsistentRow
    case CannotOpenDb
}

public struct SQLitePersistenceService: CarbonLogPersistenceService {
    let formatter = ISO8601DateFormatter()
    let dbFilePath: URL

    init(dbPath: URL) {
        dbFilePath = dbPath
    }

    public func persist(log _: CarbonLog) async throws {}

    public func persist(measurement: CarbonMeasurement, id: String? = nil) async throws {
        guard let db = try? SQLiteDB.fromPath(filepath: dbFilePath.absoluteString).dbPointer else {
            print("NIL")
            return
        }
        var insertStatement: OpaquePointer?
        let insertStatementString = """
          INSERT INTO CarbonMeasurement (id, carbonKg, date, comment) VALUES (?, ?, ?, ?);
        """

        let prepareStatementResult = sqlite3_prepare_v2(db, insertStatementString, -1, &insertStatement, nil)
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
}

// TODO: https://www.kodeco.com/6620276-sqlite-with-swift-tutorial-getting-started?page=3#toc-anchor-014
struct SQLiteDB {
    let dbPointer: OpaquePointer?

    private init(dbPointer: OpaquePointer) {
        self.dbPointer = dbPointer
    }

    static func fromPath(filepath: String) throws -> SQLiteDB {
        var db: OpaquePointer?
        guard sqlite3_open(filepath, &db) == SQLITE_OK else { throw SQLError.CannotOpenDb }
        return SQLiteDB(dbPointer: db!)
    }

    func createMeasurementTable() throws {
        let createTableString = """
          CREATE TABLE "CarbonMeasurement" (
            "id"	TEXT NOT NULL UNIQUE,
            "carbonKg"	NUMERIC NOT NULL,
            "date"	TEXT NOT NULL,
            "comment"	TEXT,
            PRIMARY KEY("id")
          );
        """

        var createTableStatement: OpaquePointer?

        let prepareReturnCode = sqlite3_prepare_v2(dbPointer, createTableString, -1, &createTableStatement, nil)

        if prepareReturnCode == SQLITE_OK {
            // 3
            if sqlite3_step(createTableStatement) == SQLITE_DONE {
                print("\ntable created.")
            } else {
                print("\ntable is not created.")
            }
        } else {
            print("\nCREATE TABLE statement is not prepared. code: \(prepareReturnCode)")
        }
        // 4
        sqlite3_finalize(createTableStatement)
    }

    //  deinit {
//      sqlite3_close(self.dbPointer)
    //  }
}
