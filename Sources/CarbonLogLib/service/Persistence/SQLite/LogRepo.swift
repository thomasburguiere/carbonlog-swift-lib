import Foundation

protocol LogRepo {
    func create(log: CarbonLog) throws
    func delete(log: CarbonLog) throws
}

private let tableName: String = "CarbonLog"

private enum Col: String {
    case id
}

private let createTableString: String = """
  CREATE TABLE "\(tableName)" (
    "\(Col.id)"	    TEXT NOT NULL,
    PRIMARY KEY(\(Col.id))
  );
"""

struct SQLiteLogRepo: LogRepo {
    let db: SQLiteDB

    init(db: SQLiteDB) throws {
        self.db = db
        try db.createTableIfNotExist(tableName, withCreateQuery: createTableString)
    }

    func create(log: CarbonLog) throws {
        let query = """
            INSERT INTO \(tableName) (
                \(Col.id)
            )
            VALUES (?)
        """
        let statement = try db.prepareStament(statement: query)
        defer { statement.finalize() }

        statement.bind(text: log.id, atPos: 1)
        let status = statement.executeStep()
        if status != .Done {
            throw SQLError.SQLiteErrorWithStatus("could not insert log row", status)
        }
    }

    func delete(log: CarbonLog) throws {
        let query = "DELETE FROM \(tableName) WHERE \(Col.id) = ?"
        let statement = try db.prepareStament(statement: query)
        defer { statement.finalize() }

        statement.bind(text: log.id, atPos: 1)
        let status = statement.executeStep()
        if status != .Done {
            throw SQLError.SQLiteErrorWithStatus("could not delete log row", status)
        }
    }
}
