import Foundation

func ensureEmptyTempFile(filename: String) -> URL {
    let tempFolderURL = FileManager.default.temporaryDirectory
    let tempOutFileURL = tempFolderURL.appending(component: filename)

    do { try FileManager.default.removeItem(at: tempOutFileURL) } catch {}
    return tempOutFileURL
}
