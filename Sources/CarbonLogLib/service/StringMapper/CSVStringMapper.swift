import Foundation

enum CsvError: Error {
    case unparseableCsvString
    case invalidCarbonMeasurementInCsv
}

struct CsvMapper: CarbonLogStringMapper {
    func logToString(log: CarbonLog) -> String? {
        log.csvString
    }

    func stringToLog(string: String) -> CarbonLog? {
        CarbonLog.fromCsvString(csv: string)
    }
}

extension CarbonMeasurement {
    var csvString: String {
        let isoDateString = ISO8601DateFormatter().string(from: date)

        let mandatoryPart = "\(isoDateString),\(String(format: "%.2f", carbonKg)),\(id)"

        let finalCsv: String = if let comment {
            mandatoryPart + "," + comment
        } else {
            mandatoryPart
        }

        return finalCsv
    }

    init(csvString: String) throws {
        let parts = csvString.split(separator: ",")
        if parts.count < 3 {
            throw CsvError.unparseableCsvString
        }

        let date = ISO8601DateFormatter().date(from: String(parts[0]))
        let carbonKg = Double(String(parts[1]))
        let id = String(parts[2])

        guard let date, let carbonKg else {
            throw CsvError.invalidCarbonMeasurementInCsv
        }
        self.date = date
        self.carbonKg = carbonKg
        self.id = id
        if parts.count > 3 {
            comment = String(parts[3])
        } else {
            comment = nil
        }
    }
}

extension CarbonLog {
    static func fromCsvString(csv: String) -> CarbonLog? {
        let lines = csv.split(separator: "\n")
        if lines.count == 0 { return nil }
        let measurements = lines.compactMap { try? CarbonMeasurement(csvString: String($0)) }
        if measurements.count == 0 { return nil }

        return CarbonLog(with: measurements)
    }

    var csvString: String {
        measurements.reduce("") { acc, next in acc + next.csvString + "\n" }
    }
}
