import Foundation
import Testing

@testable import CarbonLogLib

private let calendar: Calendar = .init(identifier: .gregorian)
private let date1 =
    calendar
        .date(from: DateComponents(timeZone: TimeZone(identifier: "GMT"), year: 2022, month: 1, day: 1, hour: 12))!
private let date2 =
    calendar
        .date(from: DateComponents(timeZone: TimeZone(identifier: "GMT"), year: 2022, month: 1, day: 2, hour: 12))!
private let date3 =
    calendar
        .date(from: DateComponents(timeZone: TimeZone(identifier: "GMT"), year: 2022, month: 1, day: 3, hour: 12))!

@Suite("CSV extensions")
struct CsvExtensions {
    private let cm2 = CarbonMeasurement(kg: 2.0, at: date2)
    private let cm3 = CarbonMeasurement(kg: 3.0, at: date3)

    @Test("shoud dump measurement to CSV row")
    func shouldGenerateMeasurementCsv() throws {
        // when
        let result2 = cm2.csvString
        let result3 = cm3.csvString

        // then
        #expect(result2 == "2022-01-02T12:00:00Z,2.00")
        #expect(result3 == "2022-01-03T12:00:00Z,3.00")
    }

    @Test("shoud dump measurement to CSV row with custom comment")
    func shouldGenerateMeasurementCsvWithComment() throws {
        let eq = CarbonEquivalent(type: .carKm, amount: 300)
        let cm = CarbonMeasurement(by: eq, at: date2, comment: "test comment")
        // when
        let result = cm.csvString

        // then
        #expect(result == "2022-01-02T12:00:00Z,111.60,test comment")
    }

    @Test("shoud dump measurement to CSV row with comment based on equivalent description")
    func shouldGenerateMeasurementCsvWithCommentFromEquivalent() throws {
        let eq = CarbonEquivalent(type: .carKm, amount: 300)
        let cm = CarbonMeasurement(by: eq, at: date2)
        // when
        let result = cm.csvString

        // then
        #expect(result == "2022-01-02T12:00:00Z,111.60,300.00 carKm")
    }

    @Test("should load CarbonMeasurement from CSV row")
    func initCmCsvString() throws {
        let csv = "2022-01-01T23:00:00Z,2.0"

        let cm = try CarbonMeasurement(csvString: csv)

        #expect(cm.carbonKg == 2.0)
    }

    @Test("should load CarbonMeasurement with comment from CSV row")
    func initCmCsvStringComment() throws {
        let csv = "2022-01-01T23:00:00Z,2.0,comment"

        let cm = try CarbonMeasurement(csvString: csv)

        #expect(cm.carbonKg == 2.0)
        #expect(cm.comment == "comment")
    }

    @Test("should dump CarbonLog to CSV") func dumpLogCsvString() throws {
        // given
        let log = CarbonLog(with: [cm2, cm3])

        // when
        let result = log.csvString

        // then
        let expected =
            "2022-01-02T12:00:00Z,2.00" + "\n" + "2022-01-03T12:00:00Z,3.00" + "\n"
        #expect(result == expected)
    }

    @Test("should throw Error when measurement cannot be parsed from invalid CSV string")
    func invalidCsv() async throws {
        let unparseableCsv = "noop"

        #expect(throws: CsvError.unparseableCsvString) {
            try CarbonMeasurement(csvString: unparseableCsv)
        }
    }

    @Test("should throw Error when measurement date cannot be parsed from CSV string")
    func invalidDateInCsv() async throws {
        let csvWithInvalidDate = "wrongDate,2.0"

        #expect(throws: CsvError.invalidCarbonMeasurementInCsv) {
            try CarbonMeasurement(csvString: csvWithInvalidDate)
        }
    }

    @Test("should throw Error when measurement carbonKg cannot be parsed from CSV string")
    func invalidCarbonKgInCsv() async throws {
        let csvWithInvalidCarbonKg = "2022-01-01T23:00:00Z,invalidKg"

        #expect(throws: CsvError.invalidCarbonMeasurementInCsv) {
            try CarbonMeasurement(csvString: csvWithInvalidCarbonKg)
        }
    }
}
