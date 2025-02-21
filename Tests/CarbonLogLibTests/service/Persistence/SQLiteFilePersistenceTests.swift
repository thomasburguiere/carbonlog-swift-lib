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

func ensureEmptyTempFile(filename: String) -> URL {
    let tempFolderURL = FileManager.default.temporaryDirectory
    let tempOutFileURL = tempFolderURL.appending(component: filename)

    do { try FileManager.default.removeItem(at: tempOutFileURL) } catch {}
    return tempOutFileURL
}

@Suite("SQLite Persistence")
struct name {
    @Test("should create table only once and throw error when duplicating it")
    func name2() async throws {
        let tempOutFileURL = ensureEmptyTempFile(filename: "test1.sqlite")

        let service = try! SQLitePersistenceService(dbPath: tempOutFileURL)

        try! service.createMeasurementTable()
        #expect(
            throws: SQLError.DuplicateTable("CarbonMeasurement"),
            performing: service.createMeasurementTable
        )
    }

    private let cm2 = CarbonMeasurement(kg: 42.0, at: date2, comment: "kurwa comment")
    @Test("should insert and retrieve single measurement") func testName() async throws {
        let tempOutFileURL = ensureEmptyTempFile(filename: "test2.sqlite")

        let service = try! SQLitePersistenceService(dbPath: tempOutFileURL)

        try! service.createMeasurementTable()

        // when
        try await service.persist(measurement: cm2, id: "kurwa")
        let persisted = try #require(try service.load(measurementId: "kurwa"))

        #expect(persisted.carbonKg == 42)
        #expect(persisted.date.description == "2022-01-02 12:00:00 +0000")
        #expect(persisted.comment == "kurwa comment")
    }
}
