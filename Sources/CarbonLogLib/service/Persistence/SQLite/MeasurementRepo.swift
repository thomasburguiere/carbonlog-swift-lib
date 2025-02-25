import Foundation

protocol MeasurementRepo {
    func create(measurement: CarbonMeasurement, forLogId: LogId) throws
    func read(measurementId: MeasurementId) throws -> CarbonMeasurement?
    func readMany(forLogId: LogId) throws -> [CarbonMeasurement]
    func update(measurement: CarbonMeasurement) throws
    func delete(measurement: CarbonMeasurement) throws
    func delete(forLogId: LogId) throws
}

private let tableName: String = "CarbonMeasurement"
private enum EntityCol: String, CaseIterable {
    case id
    case date
    case carbonKg
    case comment
    static var forSelect: String {
        allCases.reduce("") {
            if $0 != "" { return $0 + "," + $1.rawValue } else { return $1.rawValue }
        }
    }
}

private enum OtherCol: String {
    case logId
}

private extension SQLiteStatement {
    func extractMeasurement() throws -> CarbonMeasurement {
        let formatter = ISO8601DateFormatter()
        let id: String? = getRowTextCell(atPos: 0)
        let date: Date? = formatter.date(from: getRowTextCell(atPos: 1))
        let carbonKg: Double? = getRowDoubleCell(atPos: 2)
        let comment: String? = getRowTextCell(atPos: 3)

        guard let date, let carbonKg, let id else {
            throw PersistenceError.InconsistentContent
        }
        return CarbonMeasurement(kg: carbonKg, at: date, comment: comment, id: id)
    }
}

private let createTableString: String = """
  CREATE TABLE "\(tableName)" (
    "\(EntityCol.id)"        TEXT NOT NULL UNIQUE,
    "\(EntityCol.carbonKg)"  NUMERIC NOT NULL,
    "\(EntityCol.date)"	    TEXT NOT NULL,
    "\(EntityCol.comment)"	TEXT,
    "\(OtherCol.logId)"	    TEXT NOT NULL,
    PRIMARY KEY(\(EntityCol.id)),
    FOREIGN KEY(\(OtherCol.logId)) REFERENCES "CarbonLog"("id")
  );
"""

struct SQLiteMeasurementRepo: MeasurementRepo {
    let db: SQLiteDB
    let formatter = ISO8601DateFormatter()

    init(dbPath: URL) throws {
        db = try SQLiteDB.fromPath(filepath: dbPath.absoluteString)
        try db.createTableIfNotExist(tableName, withCreateQuery: createTableString)
    }

    func read(measurementId id: MeasurementId) throws -> CarbonMeasurement? {
        let query = """
          SELECT \(EntityCol.forSelect)
          FROM \(tableName)
          WHERE \(EntityCol.id) = ?;
        """
        let statement: SQLiteStatement = try db.prepareStament(statement: query)
        defer { statement.finalize() }

        statement.bind(text: id, atPos: 1)
        guard statement.executeStep() == .Row else { return nil }

        return try statement.extractMeasurement()
    }

    func readMany(forLogId logId: LogId) throws -> [CarbonMeasurement] {
        let query = """
          SELECT \(EntityCol.forSelect)
          FROM \(tableName)
          WHERE \(OtherCol.logId) = ?;
        """
        let statement: SQLiteStatement = try db.prepareStament(statement: query)
        defer { statement.finalize() }

        statement.bind(text: logId, atPos: 1)

        var arr: [CarbonMeasurement] = []
        while statement.executeStep() == .Row {
            try arr.append(statement.extractMeasurement())
        }
        return arr
    }

    func create(measurement: CarbonMeasurement, forLogId logId: LogId) throws {
        let query = """
            INSERT INTO \(tableName) (
            \(EntityCol.id),
            \(EntityCol.carbonKg),
            \(EntityCol.date),
            \(OtherCol.logId),
            \(EntityCol.comment))
            VALUES (?, ?, ?, ?, ?);
        """
        let statement: SQLiteStatement = try db.prepareStament(statement: query)
        defer { statement.finalize() }

        let id = measurement.id
        let carbonKg = measurement.carbonKg
        let dateString = formatter.string(from: measurement.date)

        statement.bind(text: id, atPos: 1)
        statement.bind(double: carbonKg, atPos: 2)
        statement.bind(text: dateString, atPos: 3)
        statement.bind(text: logId, atPos: 4)
        if let comment = measurement.comment {
            statement.bind(text: comment, atPos: 5)
        }

        let status = statement.executeStep()
        if status != .Done {
            throw SQLError.SQLiteErrorWithStatus("Could not insert row", status)
        }
    }

    func update(measurement: CarbonMeasurement) throws {
        let query = """
            UPDATE \(tableName)
            SET
                 \(EntityCol.carbonKg) = ?,
                 \(EntityCol.date)     = ?,
                 \(EntityCol.comment)  = ?
            WHERE \(EntityCol.id) = ?
        """
        let statement = try db.prepareStament(statement: query)
        defer { statement.finalize() }

        let carbonKg = measurement.carbonKg
        let dateString = formatter.string(from: measurement.date)
        let comment = measurement.comment
        let id = measurement.id

        statement.bind(double: carbonKg, atPos: 1)
        statement.bind(text: dateString, atPos: 2)
        if let comment {
            statement.bind(text: comment, atPos: 3)
        }
        statement.bind(text: id, atPos: 4)

        let status = statement.executeStep()
        if status != .Done {
            throw SQLError.SQLiteErrorWithStatus("Could not update row", status)
        }
    }

    func delete(measurement: CarbonMeasurement) throws {
        let query = "DELETE from \(tableName) WHERE id = ?"
        let statement = try db.prepareStament(statement: query)
        defer { statement.finalize() }

        statement.bind(text: measurement.id, atPos: 1)
        let status = statement.executeStep()
        if status != .Done { throw SQLError.SQLiteErrorWithStatus("Could not delete row", status) }
    }

    func delete(forLogId logId: LogId) throws {
        let query = "DELETE FROM \(tableName) WHERE \(OtherCol.logId) = ?"
        let statement = try db.prepareStament(statement: query)
        defer { statement.finalize() }

        statement.bind(text: logId, atPos: 1)
        let status = statement.executeStep()
        if status != .Done {
            throw SQLError.SQLiteErrorWithStatus(
                "Could not delete measurement rows",
                status
            )
        }
    }
}
