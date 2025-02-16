import Foundation

public enum FileFormat {
    case CSV
    case JSON

    var mapper: CarbonLogStringMapper {
        switch self {
        case .CSV: return CsvMapper()
        case .JSON: return JsonMapper()
        }
    }
}

public protocol CarbonLogStringMapper {
    func logToString(log: CarbonLog) -> String?
    func stringToLog(string: String) -> CarbonLog?
}
