import Foundation

public enum SQLError: Error, Equatable {
    case CouldNotPrepareStatement
    case InconsistentRow
    case CannotOpenDb
    case DuplicateTable(String)
    case SQLiteErrorWithStatus(String, SQLiteStatus)
}

private extension CarbonMeasurement {
    static var sqlTableName: String { "CarbonMeasurement" }
    static var sqlTableString: String { """
      CREATE TABLE "\(sqlTableName)" (
        "id"	TEXT NOT NULL UNIQUE,
        "carbonKg"	NUMERIC NOT NULL,
        "date"	TEXT NOT NULL,
        "comment"	TEXT,
        "logId"	TEXT NOT NULL,
        PRIMARY KEY("id"),
        FOREIGN KEY("logId") REFERENCES "\(CarbonLog.sqlTableName)"("id")
      );
    """
    }
}

private extension CarbonLog {
    static var sqlTableName: String { "CarbonLog" }
    static var sqlTableString: String { """
    CREATE TABLE "\(sqlTableName)" (
      "id"	TEXT NOT NULL UNIQUE,
      PRIMARY KEY("id")
    )
    """
    }
}

public struct SQLitePersistenceService: CarbonLogPersistenceService {
    let formatter = ISO8601DateFormatter()
    let db: SQLiteDB
    let measurementRepo: MeasurementRepo

    init(dbPath: URL) throws {
        db = try SQLiteDB.fromPath(filepath: dbPath.absoluteString)
        measurementRepo = SQLiteMeasurementRepo(db: db)
    }

    public func persist(log _: CarbonLog) async throws {}
    public func insert(log: CarbonLog) async throws {
        let insertStatementString = "INSERT INTO CarbonLog (id) VALUES (?);"

        let insertStatement: SQLiteStatement = try db.prepareStament(statement: insertStatementString)
        defer { insertStatement.finalize() }

        insertStatement.bind(text: log.id, atPos: 1)
        let status = insertStatement.executeStep()
        if status == .Done {
            print("\nSuccessfully inserted row.")
        } else {
            throw SQLError.SQLiteErrorWithStatus("Could not insert row", status)
        }
    }

    public func load(id _: String) async -> CarbonLog? {
        return nil
    }

    public func append(measurement _: CarbonMeasurement, toLogWithId _: String) async throws {}

    public func insert(measurement: CarbonMeasurement, forLogId logId: String) throws {
        try measurementRepo.create(measurement: measurement, forLogId: logId)
    }

    public func delete(measurement: CarbonMeasurement) throws {
        try measurementRepo.delete(measurement: measurement)
    }

    public func load(measurementId id: String) throws -> CarbonMeasurement? {
        return try measurementRepo.read(measurementId: id)
    }

    public func update(measurement: CarbonMeasurement) throws {
        try measurementRepo.update(measurement: measurement)
    }

    func createTables() throws {
        try createTable(CarbonLog.sqlTableName, withCreateQuery: CarbonLog.sqlTableString)
        try createTable(CarbonMeasurement.sqlTableName, withCreateQuery: CarbonMeasurement.sqlTableString)
    }

    private func createTable(_ tableName: String, withCreateQuery query: String) throws {
        if try db.tableExists(tableName: tableName) { throw SQLError.DuplicateTable(tableName) }

        try db.executeStatement(statement: query)
    }
}
