import Foundation

enum SQLError: Error, Equatable {
    case CouldNotPrepareStatement
    case CannotOpenDb(String)
    case DuplicateTable(String)
    case SQLiteErrorWithStatus(String, SQLiteStatus)
}

public typealias LogId = String
public typealias MeasurementId = String

public enum PersistenceError: Error, Equatable {
    case InconsistentContent
    case inconsistentOperation(String? = nil)
}

public struct SQLPersistenceService: CarbonLogPersistenceService {
    let formatter = ISO8601DateFormatter()
    let measurementRepo: MeasurementRepo
    let logRepo: LogRepo

    init(logRepo: LogRepo, measurementRepo: MeasurementRepo) {
        self.logRepo = logRepo
        self.measurementRepo = measurementRepo
    }

    public func persist(log: CarbonLog) async throws {
        if try logRepo.read(logId: log.id) == nil {
            try logRepo.create(log: log)
        } else {
            try measurementRepo.delete(forLogId: log.id)
        }
        try log.measurements.forEach { measurement in
            try measurementRepo.create(measurement: measurement, forLogId: log.id)
        }
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

    func delete(measurement: CarbonMeasurement) throws {
        try measurementRepo.delete(measurement: measurement)
    }

    func load(measurementId id: String) throws -> CarbonMeasurement? {
        return try measurementRepo.read(measurementId: id)
    }
}
