import Foundation

public protocol CarbonLogPersistenceService {
    func persist(log: CarbonLog) async throws
    func load(id: String) async -> CarbonLog?
}

public struct CsvPersistenceService: CarbonLogPersistenceService {

    let csvURL: URL

    public init(csvURL: URL) {
        self.csvURL = csvURL
    }

    public func persist(log: CarbonLog) async throws {
        try log.csvString.write(to: self.csvURL, atomically: true, encoding: String.Encoding.utf8)
    }

    public func load(id _: String) async -> CarbonLog? {

        let fileContents = try? String(contentsOf: self.csvURL, encoding: String.Encoding.utf8)

        let lines = fileContents?.split(separator: "\n")
        guard let lines else { return nil }
        let measurements = try? lines.map { s in try CarbonMeasurement(csvString: String(s)) }

        guard let measurements else { return nil }
        return CarbonLog(with: measurements)
    }
}

public enum CsvError: Error {
    case unparseableCsvString
    case invalidCarbonMeasurementInCsv
}

extension CarbonMeasurement {
    var csvString: String {
        let isoDateString = ISO8601DateFormatter().string(from: self.date)

        let dateAndAmountCsv = "\(isoDateString),\(String(format: "%.2f", self.carbonKg))"

        let finalCsv: String

        if let comment = self.comment {
            finalCsv = dateAndAmountCsv + "," + comment
        }
        else {
            finalCsv = dateAndAmountCsv
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
            self.comment = String(parts[2])
        }
        else {
            self.comment = nil
        }
    }
}

extension CarbonLog {
    var csvString: String {
        measurements.reduce("") { acc, next in acc + next.csvString + "\n" }
    }
}
