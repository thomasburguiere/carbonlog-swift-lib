import Foundation

public struct GoogleSheetPersistenceService: CarbonLogPersistenceService {
    public func persist(log _: CarbonLog) async throws {}

    public func load(id _: String) async -> CarbonLog? {
        return nil
    }

    public func append(measurement _: CarbonMeasurement, toLogWithId _: String) async throws {}
}
