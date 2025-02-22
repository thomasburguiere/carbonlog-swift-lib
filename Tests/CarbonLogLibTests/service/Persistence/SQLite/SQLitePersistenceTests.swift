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
struct SqlitePersistenceTests {
    @Test("should create table only once and throw error when duplicating it")
    func shouldThrowWhenCreatingTableTwice() async throws {
        let tempOutFileURL = ensureEmptyTempFile(filename: "test1.sqlite")

        let service = try! SQLitePersistenceService(dbPath: tempOutFileURL)

        try! service.createTables()
        #expect(
            throws: SQLError.DuplicateTable("CarbonLog"),
            performing: service.createTables
        )
    }

    private let cm2 = CarbonMeasurement(
        kg: 42.0,
        at: date2,
        comment: "kurwa comment",
        id: "id-2"
    )
    @Test("should insert, load and delete single measurement")
    func shouldInsertLoadAndDeleteMeasurment() async throws {
        let tempOutFileURL = ensureEmptyTempFile(filename: "test2.sqlite")

        let service = try! SQLitePersistenceService(dbPath: tempOutFileURL)

        try! service.createTables()

        let log = CarbonLog()
        try! await service.persist(log: log)

        // when
        try service.insert(measurement: cm2, forLogId: log.id)
        // then
        let persisted = try #require(try service.load(measurementId: "id-2"))
        #expect(persisted.carbonKg == 42)
        #expect(persisted.date.description == "2022-01-02 12:00:00 +0000")
        #expect(persisted.comment == "kurwa comment")

        // when
        try service.delete(measurement: cm2)
        // then
        let deleted = try service.load(measurementId: "id-2")
        #expect(deleted == nil)
    }

    @Test("should update single measurement")
    func shouldUpdateMeasurement() async throws {
        let tempOutFileURL = ensureEmptyTempFile(filename: "test3.sqlite")

        let service = try! SQLitePersistenceService(dbPath: tempOutFileURL)
        try! service.createTables()

        let log = CarbonLog()
        try! await service.persist(log: log)

        // given
        try service.insert(measurement: cm2, forLogId: log.id)
        let persisted = try #require(try service.load(measurementId: "id-2"))
        #expect(persisted.carbonKg == 42)

        // when
        let updatedMeasurement = CarbonMeasurement(
            kg: 666,
            at: cm2.date.addingTimeInterval(86400), // + 1 day
            comment: "updated comment",
            id: cm2.id
        )
        print(tempOutFileURL)
        try service.update(measurement: updatedMeasurement)
        let persistedUpdated = try #require(try service.load(measurementId: "id-2"))

        // then
        #expect(persistedUpdated.carbonKg == 666)
        #expect(persistedUpdated.comment == "updated comment")
    }
}
