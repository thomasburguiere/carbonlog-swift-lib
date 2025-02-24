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

    public func persist(log: CarbonLog) async throws {
        if try logRepo.read(logId: log.id) == nil {
            try logRepo.create(log: log)
            try log.measurements.forEach { measurement in
                try measurementRepo.create(measurement: measurement, forLogId: log.id)
            }
        } else {
            try log.measurements.forEach { measurement in
                try persist(measurement: measurement, forLogId: log.id)
            }
        }
    }

    func insert(log: CarbonLog) async throws {
        try logRepo.create(log: log)
    }

    public func load(id: String) async throws -> CarbonLog? {
        guard let log = try logRepo.read(logId: id) else { return nil }

        let logMeasurements = try measurementRepo.readMany(forLogId: id)
        let updated = log.add(measurements: logMeasurements)
        return updated
    }

    public func append(measurement: CarbonMeasurement, toLogWithId logId: LogId) async throws {
        let exists = try measurementRepo.read(measurementId: measurement.id) != nil
        guard exists == false else {
            throw PersistenceError
                .inconsistentOperation("Trying to append a measurement which already exists")
        }
        try measurementRepo.create(measurement: measurement, forLogId: logId)
    }

    func persist(measurement: CarbonMeasurement, forLogId logId: LogId) throws {
        if try measurementRepo.read(measurementId: measurement.id) != nil {
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
