import Foundation

private let sqlTableName: String = "CarbonMeasurement"

private enum Col: String {
    case id
    case carbonKg
    case date
    case comment
    case logId
}

private let sqlCreateTableString: String = """
  CREATE TABLE "\(sqlTableName)" (
    "\(Col.id)"        TEXT NOT NULL UNIQUE,
    "\(Col.carbonKg)"  NUMERIC NOT NULL,
    "\(Col.date)"	    TEXT NOT NULL,
    "\(Col.comment)"	TEXT,
    "\(Col.logId)"	    TEXT NOT NULL,
    PRIMARY KEY(\(Col.id)),
    FOREIGN KEY(\(Col.logId)) REFERENCES "CarbonLog"("id")
  );
"""

protocol MeasurementRepo {
    func create(measurement: CarbonMeasurement, forLogId: String) throws
    func read(measurementId: String) throws -> CarbonMeasurement?
    func delete(measurement: CarbonMeasurement) throws
    func update(measurement: CarbonMeasurement) throws
}

struct SQLiteMeasurementRepo: MeasurementRepo {
    func read(measurementId id: String) throws -> CarbonMeasurement? {
        let selectStatementString = """
          SELECT \(Col.date), \(Col.carbonKg), \(Col.comment)
          FROM \(sqlTableName)
          WHERE \(Col.id) = ?;
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

    let db: SQLiteDB
    let formatter = ISO8601DateFormatter()

    func create(measurement: CarbonMeasurement, forLogId logId: String) throws {
        let insertStatementString = """
            INSERT INTO \(sqlTableName) (
            \(Col.id),
            \(Col.carbonKg),
            \(Col.date),
            \(Col.logId),
            \(Col.comment))
            VALUES (?, ?, ?, ?, ?);
        """
        let insertStatement: SQLiteStatement = try db.prepareStament(statement: insertStatementString)
        defer { insertStatement.finalize() }

        let id = measurement.id
        let carbonKg = measurement.carbonKg
        let dateString = formatter.string(from: measurement.date)

        insertStatement.bind(text: id, atPos: 1)
        insertStatement.bind(double: carbonKg, atPos: 2)
        insertStatement.bind(text: dateString, atPos: 3)
        insertStatement.bind(text: logId, atPos: 4)
        if let comment = measurement.comment {
            insertStatement.bind(text: comment, atPos: 5)
        }

        let status = insertStatement.executeStep()
        if status != .Done {
            throw SQLError.SQLiteErrorWithStatus("Could not insert row", status)
        }
    }

    func update(measurement: CarbonMeasurement) throws {
        let query = """
            UPDATE \(sqlTableName)
            SET
                 \(Col.carbonKg) = ?,
                 \(Col.date)     = ?,
                 \(Col.comment)  = ?
            WHERE \(Col.id) = ?
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
        let deleteString = "DELETE from \(sqlTableName) WHERE id = ?"
        let statement = try db.prepareStament(statement: deleteString)
        defer { statement.finalize() }

        statement.bind(text: measurement.id, atPos: 1)
        let status = statement.executeStep()
        if status != .Done { throw SQLError.SQLiteErrorWithStatus("Could not delete row", status) }
    }
}
