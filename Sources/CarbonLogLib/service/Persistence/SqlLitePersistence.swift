import Foundation
import SQLite3

public struct SQLitePersistenceService: CarbonLogPersistenceService {
    public func persist(log _: CarbonLog) async throws {}

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
