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

        let dateAndAmountCsv = "\(isoDateString),\(String(format: "%.2f", carbonKg))"

        let finalCsv: String = if let comment {
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
