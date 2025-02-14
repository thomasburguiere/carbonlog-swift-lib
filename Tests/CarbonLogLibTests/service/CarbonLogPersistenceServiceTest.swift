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

@Suite("CarbonLog CSV Persistence")
struct CarbonLogPersistenceServiceTests {
    private let cm2 = CarbonMeasurement(kg: 2.0, at: date2)

    // test
    private let cm3 = CarbonMeasurement(kg: 3.0, at: date3)

    @Test("Should persist and load CarbonLog")
    func persistAndLoadLog() async throws {
        let tempFolderURL = FileManager.default.temporaryDirectory
        let tempOutFileURL = tempFolderURL.appending(component: "test.csv")

        let log = CarbonLog(with: [cm2, cm3])
        let csvService = CsvPersistenceService(csvURL: tempOutFileURL)

        // when
        try await csvService.persist(log: log)
        let loadedLog = try #require(await CsvPersistenceService(csvURL: tempOutFileURL).load(id: "noop"))

        // then
        #expect(loadedLog.measurements.count == 2)
    }

    func getInputFilePathURL(fileName: String) -> URL {
        Bundle.module.url(forResource: fileName, withExtension: "csv")!
    }

    @Test("Should persist updates to CarbonLog")
    func persistUpdateToLogLog() async throws {
        // given
        let service = CsvPersistenceService(csvURL: getInputFilePathURL(fileName: "test-input"))
        let initialLog = try #require(await service.load(id: "noop"))
        #expect(initialLog.measurements.count == 2)

        let additionalMeasurement = CarbonMeasurement(
            by: CarbonEquivalent(type: .carKm, amount: 250),
            at: date3,
            comment: "appended measurement"
        )

        // when
        try await service.append(measurement: additionalMeasurement, toLogWithId: "noop")

        // then
        let updatedLog = try #require(await service.load(id: "noop"))
        #expect(updatedLog.measurements.count == 3)
        let persistedAdditionalMeasurement = updatedLog.measurements.first { $0.comment == "appended measurement" }
        #expect(persistedAdditionalMeasurement != nil)
        #expect(persistedAdditionalMeasurement?.date.description == "2022-01-03 12:00:00 +0000")
        #expect(persistedAdditionalMeasurement?.carbonKg == 93)
    }

    @Test("Should load CarbonLog from CSV")
    func loadCsvLog() async throws {
        let csvService = CsvPersistenceService(csvURL: getInputFilePathURL(fileName: "test-input"))
        let loadedLog = try #require(await csvService.load(id: "noop"))

        // then
        #expect(loadedLog.measurements.count == 2)
    }

    @Test("Should return nil when loading empty CSV")
    func handleEmptyCsv() async throws {
        let csvService = CsvPersistenceService(csvURL: getInputFilePathURL(fileName: "test-empty"))
        let loadedLog = await csvService.load(id: "noop")

        #expect(loadedLog == nil)
    }

    @Test("Should return nil when loading garbage CSV")
    func handleGarbageCsv() async throws {
        let inputFilePathURL = Bundle.module.url(forResource: "test-garbage", withExtension: "csv")
        let csvService = CsvPersistenceService(csvURL: inputFilePathURL!)
        let loadedLog = await csvService.load(id: "noop")

        #expect(loadedLog == nil)
    }

    @Test("Should return handle CSV with mixed valid invalid content")
    func handleMixedGarbageCsv() async throws {
        let inputFilePathURL = Bundle.module.url(forResource: "test-mixed-input", withExtension: "csv")
        let csvService = CsvPersistenceService(csvURL: inputFilePathURL!)
        let loadedLog = await csvService.load(id: "noop")

        #expect(loadedLog?.measurements.count == 2)
    }

    @Suite("CSV string parsing & dumping")
    struct CsvStuff {
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
}
