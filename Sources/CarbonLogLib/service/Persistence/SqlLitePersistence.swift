import Foundation
import SQLite3

public struct SQLitePersistenceService: CarbonLogPersistenceService {
    let formatter = ISO8601DateFormatter()
    let dbFilePath: URL

    init(dbPath: URL) {
        dbFilePath = dbPath
    }

    public func persist(log _: CarbonLog) async throws {}

    public func persist(measurement: CarbonMeasurement) async throws {
        let db = openDatabase(filepath: dbFilePath.absoluteString)
        var insertStatement: OpaquePointer?
        let insertStatementString = """
          INSERT INTO CarbonMeasurement (id, carbonKg, date) VALUES (?, ?, ?);
        """
        if sqlite3_prepare_v2(db, insertStatementString, -1, &insertStatement, nil) ==
            SQLITE_OK
        {
            let id: NSString = UUID().uuidString as NSString
            let carbonKg = measurement.carbonKg
            let date: NSString = formatter.string(from: measurement.date) as NSString
            // 2
            sqlite3_bind_text(insertStatement, 1, id.utf8String, -1, nil)
            sqlite3_bind_double(insertStatement, 2, carbonKg)
            sqlite3_bind_text(insertStatement, 3, date.utf8String, -1, nil)
            // 4
            if sqlite3_step(insertStatement) == SQLITE_DONE {
                print("\nSuccessfully inserted row.")
            } else {
                print("\nCould not insert row.")
            }
        } else {
            print("\nINSERT statement is not prepared.")
        }
    }

    public func load(id _: String) async -> CarbonLog? {
        return nil
    }

    public func append(measurement _: CarbonMeasurement, toLogWithId _: String) async throws {}
}

func openDatabase(filepath: String) -> OpaquePointer? {
    var db: OpaquePointer?
    if sqlite3_open(filepath, &db) == SQLITE_OK {
        print("Successfully opened connection to database at \(filepath)")
        return db
    } else {
        print("Unable to open database.")
        return nil
    }
}

func createTable(db: OpaquePointer?, createTableString: String) {
    var createTableStatement: OpaquePointer?

    let prepareReturnCode = sqlite3_prepare_v2(db, createTableString, -1, &createTableStatement, nil)

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
