import Foundation

struct JsonMapper: CarbonLogStringMapper {
    func logToString(log: CarbonLog) -> String? {
        return log.toJson()!
    }

    func stringToLog(string: String) -> CarbonLog? {
        return CarbonLog.fromJson(string)
    }
}

let encoder = JSONEncoder()
let decoder = JSONDecoder()

private extension CarbonLog {
    func toJson() -> String? {
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(self) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func fromJson(_ json: String) -> CarbonLog? {
        decoder.dateDecodingStrategy = .iso8601
        guard let data = json.data(using: .utf8) else { return nil }
        return try? decoder.decode(CarbonLog.self, from: data)
    }
}
