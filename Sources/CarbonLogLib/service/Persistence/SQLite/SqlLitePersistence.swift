import Foundation

public enum SQLError: Error, Equatable {
    case CouldNotPrepareStatement
    case InconsistentRow
    case CannotOpenDb
    case DuplicateTable(String)
    case SQLiteErrorWithStatus(String, SQLiteStatus)
}

public struct SQLitePersistenceService: CarbonLogPersistenceService {
    let formatter = ISO8601DateFormatter()
    let measurementRepo: MeasurementRepo
    let logRepo: LogRepo

    init(dbPath: URL) throws {
        let db = try SQLiteDB.fromPath(filepath: dbPath.absoluteString)
        measurementRepo = try SQLiteMeasurementRepo(db: db)
        logRepo = try SQLiteLogRepo(db: db)
    }

    public func persist(log _: CarbonLog) async throws {}
    public func insert(log: CarbonLog) async throws {
        try logRepo.create(log: log)
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
}
