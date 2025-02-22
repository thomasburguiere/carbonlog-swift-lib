import Foundation

public enum SQLError: Error, Equatable {
    case CouldNotPrepareStatement
    case InconsistentRow
    case CannotOpenDb
    case DuplicateTable(String)
    case SQLiteErrorWithStatus(String, SQLiteStatus)
}

public enum PersistenceError: Error, Equatable {
    case inconsistentOperation(String? = nil)
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

    func insert(log: CarbonLog) async throws {
        try logRepo.create(log: log)
    }

    public func load(id _: String) async -> CarbonLog? {
        return nil
    }

    public func append(measurement: CarbonMeasurement, toLogWithId logId: LogId) async throws {
        let exists = try measurementRepo.read(measurementId: measurement.id) != nil
        guard exists == false else {
            throw PersistenceError.inconsistentOperation("Trying to append a measurement which already exists")
        }
        try measurementRepo.create(measurement: measurement, forLogId: logId)
    }

    func persist(measurement: CarbonMeasurement, forLogId logId: LogId) throws {
        let exists = try measurementRepo.read(measurementId: measurement.id) != nil
        if exists {
            try measurementRepo.update(measurement: measurement)
        } else {
            try measurementRepo.create(measurement: measurement, forLogId: logId)
        }
    }

    public func delete(measurement: CarbonMeasurement) throws {
        try measurementRepo.delete(measurement: measurement)
    }

    public func load(measurementId id: String) throws -> CarbonMeasurement? {
        return try measurementRepo.read(measurementId: id)
    }
}
