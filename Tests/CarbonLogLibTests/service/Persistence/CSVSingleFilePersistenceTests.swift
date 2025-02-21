import Foundation
import Testing

@testable import CarbonLogLib

private let calendar: Calendar = .init(identifier: .gregorian)
private let date1 =
    calendar
        .date(from: DateComponents(timeZone: gmt, year: 2022, month: 1, day: 1, hour: 12))!
private let date2 =
    calendar
        .date(from: DateComponents(timeZone: gmt, year: 2022, month: 1, day: 2, hour: 12))!
private let date3 =
    calendar
        .date(from: DateComponents(timeZone: gmt, year: 2022, month: 1, day: 3, hour: 12))!

func getInputFileCopyURL(fileName: String) -> URL {
    let inputUrl = Bundle.module.url(forResource: fileName, withExtension: "csv")!
    let outputURL =
        FileManager.default.temporaryDirectory.appending(path: fileName.appending(UUID().uuidString))

    try! FileManager.default.copyItem(at: inputUrl, to: outputURL)
    return outputURL
}

@Suite("CarbonLog Single CSV File Persistence")
struct SingleCSVPersistenceTests {
    private let cm2 = CarbonMeasurement(kg: 2.0, at: date2)

    // test
    private let cm3 = CarbonMeasurement(kg: 3.0, at: date3)

    @Test("Should persist and load CarbonLog")
    func persistAndLoadLog() async throws {
        let tempFolderURL = FileManager.default.temporaryDirectory
        let tempOutFileURL = tempFolderURL.appending(component: "test.csv")

        let log = CarbonLog(with: [cm2, cm3])
        var service = LocalStringFilePersistenceService(fileURL: tempOutFileURL, format: .CSV)

        // when
        try await service.persist(log: log)
        service = LocalStringFilePersistenceService(fileURL: tempOutFileURL, format: .CSV)
        let loadedLog = try #require(await service.load(id: "noop"))

        // then
        #expect(loadedLog.measurements.count == 2)
    }

    @Test("Should persist updates to CarbonLog")
    func persistUpdateToLogLog() async throws {
        // given
        let service = LocalStringFilePersistenceService(fileURL: getInputFileCopyURL(fileName: "test-input"), format: .CSV)
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
        let service = LocalStringFilePersistenceService(fileURL: getInputFileCopyURL(fileName: "test-input"), format: .CSV)
        let loadedLog = try #require(await service.load(id: "noop"))

        // then
        #expect(loadedLog.measurements.count == 2)
    }

    @Test("Should return nil when loading empty CSV")
    func handleEmptyCsv() async throws {
        let service = LocalStringFilePersistenceService(fileURL: getInputFileCopyURL(fileName: "test-empty"), format: .CSV)
        let loadedLog = await service.load(id: "noop")

        #expect(loadedLog == nil)
    }

    @Test("Should return nil when loading garbage CSV")
    func handleGarbageCsv() async throws {
        let service = LocalStringFilePersistenceService(fileURL: getInputFileCopyURL(fileName: "test-garbage"), format: .CSV)
        let loadedLog = await service.load(id: "noop")

        #expect(loadedLog == nil)
    }

    @Test("Should return handle CSV with mixed valid invalid content")
    func handleMixedGarbageCsv() async throws {
        let service = LocalStringFilePersistenceService(
            fileURL: getInputFileCopyURL(fileName: "test-mixed-input"),
            format: .CSV
        )
        let loadedLog = await service.load(id: "noop")

        #expect(loadedLog?.measurements.count == 2)
    }
}
