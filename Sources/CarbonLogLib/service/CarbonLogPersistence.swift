import Foundation

public protocol CarbonLogPersistenceService {
    func persist(log: CarbonLog) async throws
    func load(id: String) async -> CarbonLog?
    func append(measurement: CarbonMeasurement, toLogWithId: String) async throws
}

public struct CsvPersistenceService: CarbonLogPersistenceService {
    let csvURL: URL

    public init(csvURL: URL) {
        self.csvURL = csvURL
    }

    public func append(measurement: CarbonMeasurement, toLogWithId _: String) async throws {
        guard let log = await load(id: "noop") else { return }
        let updatedLog = log.add(measurements: [measurement])
        try await persist(log: updatedLog)
    }

    public func persist(log: CarbonLog) async throws {
        try log.csvString.write(to: csvURL, atomically: true, encoding: String.Encoding.utf8)
    }

    public func load(id _: String) async -> CarbonLog? {
        let fileContents = try? String(contentsOf: csvURL, encoding: String.Encoding.utf8)

        let lines = fileContents?.split(separator: "\n")
        guard let lines else { return nil }
        if lines.count == 0 { return nil }

        let measurements = lines.compactMap { try? CarbonMeasurement(csvString: String($0)) }
        if measurements.count == 0 { return nil }

        return CarbonLog(with: measurements)
    }
}

public enum CsvError: Error {
    case unparseableCsvString
    case invalidCarbonMeasurementInCsv
}

extension CarbonMeasurement {
    var csvString: String {
        let isoDateString = ISO8601DateFormatter().string(from: date)

        let dateAndAmountCsv = "\(isoDateString),\(String(format: "%.2f", carbonKg))"

        let finalCsv: String =
            if let comment {
                dateAndAmountCsv + "," + comment
            } else {
                dateAndAmountCsv
            }

        return finalCsv
    }

    init(csvString: String) throws {
        let parts = csvString.split(separator: ",")
        if parts.count < 2 {
            throw CsvError.unparseableCsvString
        }

        let date = ISO8601DateFormatter().date(from: String(parts[0]))
        let carbonKg = Double(String(parts[1]))

        guard let date, let carbonKg else {
            throw CsvError.invalidCarbonMeasurementInCsv
        }
        self.date = date
        self.carbonKg = carbonKg
        if parts.count > 2 {
            comment = String(parts[2])
        } else {
            comment = nil
        }
    }
}

extension CarbonLog {
    var csvString: String {
        measurements.reduce("") { acc, next in acc + next.csvString + "\n" }
    }
}
