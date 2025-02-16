import Foundation

public struct LocalFilePersistenceService: CarbonLogPersistenceService {
    let fileURL: URL
    let mapper: CarbonLogStringMapper

    public init(fileURL: URL, format: FileFormat) {
        self.fileURL = fileURL
        mapper = format.mapper
    }

    public func append(measurement: CarbonMeasurement, toLogWithId _: String) async throws {
        guard let log: CarbonLog = await load(id: "noop") else { return }
        let updatedLog: CarbonLog = log.add(measurements: [measurement])
        try await persist(log: updatedLog)
    }

    public func persist(log: CarbonLog) async throws {
        let string = mapper.logToString(log: log)
        try string?.write(to: fileURL, atomically: true, encoding: .utf8)
    }

    public func load(id _: String) async -> CarbonLog? {
        guard let fileContents = try? String(contentsOf: fileURL, encoding: .utf8) else {
            return nil
        }

        return mapper.stringToLog(string: fileContents)
    }
}
