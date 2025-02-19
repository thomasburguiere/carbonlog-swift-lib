import Foundation
import Testing

@testable import CarbonLogLib

@Suite("SQLite Persistence")
struct name {
    @Test func testName() async throws {
        let tempFolderURL = FileManager.default.temporaryDirectory
        let tempOutFileURL = tempFolderURL.appending(component: "test.sqlite")

        try FileManager.default.removeItem(at: tempOutFileURL)

        print(tempOutFileURL.absoluteString)
        let db = try? #require(openDatabase(filepath: tempOutFileURL.absoluteString))

        let createTableString = """
        CREATE TABLE "CarbonMeasurement" (
          "id"	INTEGER NOT NULL,
          "carbonKg"	NUMERIC NOT NULL,
          "date"	TEXT NOT NULL,
          "comment"	TEXT,
          PRIMARY KEY("id" AUTOINCREMENT)
        );
        """

        createTable(db: db, createTableString: createTableString)
    }
}
