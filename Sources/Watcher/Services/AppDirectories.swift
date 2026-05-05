import Foundation

enum AppDirectories {
    private static let currentDirectoryName = "Watcher"
    private static let legacyDirectoryName = "FilmMate"

    static func applicationSupportDirectory() -> URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let currentDirectory = appSupport.appendingPathComponent(currentDirectoryName, isDirectory: true)
        let legacyDirectory = appSupport.appendingPathComponent(legacyDirectoryName, isDirectory: true)

        if !FileManager.default.fileExists(atPath: currentDirectory.path),
           FileManager.default.fileExists(atPath: legacyDirectory.path) {
            try? FileManager.default.moveItem(at: legacyDirectory, to: currentDirectory)
        }

        try? FileManager.default.createDirectory(at: currentDirectory, withIntermediateDirectories: true)
        return currentDirectory
    }
}
