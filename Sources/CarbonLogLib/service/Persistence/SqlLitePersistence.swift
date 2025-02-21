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
        defer { insertStatement.finalize() }

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
        if insertStatement.executeStep() == .Done {
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
        defer { selectStatement.finalize() }

        selectStatement.bind(text: id, atPos: 1)
        guard selectStatement.executeStep() == .Row else { return nil }

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
