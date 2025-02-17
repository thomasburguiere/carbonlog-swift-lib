import Foundation

public protocol CarbonLogPersistenceService {
    func persist(log: CarbonLog) async throws
    func load(id: String) async -> CarbonLog?
    func append(measurement: CarbonMeasurement, toLogWithId: String) async throws
}
