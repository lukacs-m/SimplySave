import Foundation

public actor SimplySaveClient: SimpleSaving {
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    public init(decoder: JSONDecoder = JSONDecoder(),
                encoder: JSONEncoder = JSONEncoder()) {
        self.decoder = decoder
        self.encoder = encoder
    }
}

// MARK: - Codable
public extension SimplySaveClient {

    /// Save encodable struct to disk as JSON data
    ///
    /// - Parameters:
    ///   - value: the Encodable struct to store
    ///   - path: file location to store the data (i.e. "Folder/file.json")
    ///   - directory: user directory to store the file in
    ///   - encoder: custom JSONEncoder to encode value
    /// - Throws: Error if there were any issues encoding the struct or writing it to disk
    @discardableResult
    func save<Entity: Encodable>(_ value: Entity,
                                 as path: String,
                                 in directory: DirectoryEndpoint) async throws -> URL {
        guard !path.hasSuffix("/") else {
            throw createInvalidFileNameForStructsError()
        }
        let url = try createURL(for: path, in: directory)
        let data = try encoder.encode(value)
        try createSubfoldersBeforeCreatingFile(at: url)
        try data.write(to: url, options: .atomic)
        return url
    }
    
    /// Retrieve and decode a struct from a file on disk
    ///
    /// - Parameters:
    ///   - path: path of the file holding desired data
    ///   - directory: user directory to retrieve the file from
    ///   - type: struct type (i.e. Message.self or [Message].self)
    ///   - decoder: custom JSONDecoder to decode existing values
    /// - Returns: decoded structs of data
    /// - Throws: Error if there were any issues retrieving the data or decoding it to the specified type
    func fetch<Entity: Decodable>(from path: String,
                                  in directory: DirectoryEndpoint) async throws -> Entity {
        guard !path.hasSuffix("/") else {
            throw createInvalidFileNameForStructsError()
        }
        let url = try getExistingFileURL(for: path, in: directory)
        let data = try Data(contentsOf: url)
        let value = try decoder.decode(Entity.self, from: data)
        return value
    }

    /// Append Codable struct JSON data to a file's data
    ///
    /// - Parameters:
    ///   - value: the struct to store to disk
    ///   - path: file location to store the data (i.e. "Folder/file.json")
    ///   - directory: user directory to store the file in
    ///   - decoder: custom JSONDecoder to decode existing values
    ///   - encoder: custom JSONEncoder to encode new value
    /// - Throws: Error if there were any issues with encoding/decoding or writing the encoded struct to disk
    func append<Entity: Codable>(_ value: Entity,
                                 to path: String,
                                 in directory: DirectoryEndpoint) async throws {
        guard !path.hasSuffix("/") else {
            throw createInvalidFileNameForStructsError()
        }

        guard let url = try? getExistingFileURL(for: path, in: directory) else {
            try await save([value], as: path, in: directory)
            return
        }
        let previousData = try Data(contentsOf: url)
        guard !previousData.isEmpty else {
            try await save([value], as: path, in: directory)
            return
        }

        let newData: [Entity]
        if let old = try? decoder.decode(Entity.self, from: previousData) {
            newData = [old, value]
        } else if var old = try? decoder.decode([Entity].self, from: previousData) {
            old.append(value)
            newData = old
        } else {
            throw createDeserializationErrorForAppendingStructToInvalidType(url: url, type: value)
        }
        let newEncodedData = try encoder.encode(newData)
        try newEncodedData.write(to: url, options: .atomic)
    }


    /// Append Codable struct array JSON data to a file's data
    ///
    /// - Parameters:
    ///   - value: the Codable struct array to store
    ///   - path: file location to store the data (i.e. "Folder/file.json")
    ///   - directory: user directory to store the file in
    ///   - decoder: custom JSONDecoder to decode existing values
    ///   - encoder: custom JSONEncoder to encode new value
    /// - Throws: Error if there were any issues writing the encoded struct array to disk
    func append<Entity: Codable>(_ value: [Entity],
                                 to path: String,
                                 in directory: DirectoryEndpoint) async throws {
        guard !path.hasSuffix("/") else {
            throw createInvalidFileNameForStructsError()
        }
        guard let url = try? getExistingFileURL(for: path, in: directory) else {
            try await save(value, as: path, in: directory)
            return
        }

        let previousData = try Data(contentsOf: url)
        guard !previousData.isEmpty else {
            try await save(value, as: path, in: directory)
            return
        }

        let newData: [Entity]
        if let old = try? decoder.decode(Entity.self, from: previousData) {
            newData = [old] + value
        } else if var old = try? decoder.decode([Entity].self, from: previousData) {
            old.append(contentsOf: value)
            newData = old
        } else {
            throw createDeserializationErrorForAppendingStructToInvalidType(url: url, type: value)
        }
        let newEncodedData = try encoder.encode(newData)
        try newEncodedData.write(to: url, options: .atomic)
    }
}



/// Checking Volume Storage Capacity
/// Confirm that you have enough local storage space for a large amount of data.
///
/// Source: https://developer.apple.com/documentation/foundation/nsurlresourcekey/checking_volume_storage_capacity?changes=latest_major&language=objc
public extension SimplySaveClient {
    /// Volume’s total capacity in bytes.
    nonisolated var totalCapacity: Int? {
        let resourceValues = getVolumeResourceValues(for: .volumeTotalCapacityKey)
        return resourceValues?.volumeTotalCapacity
    }

    /// Volume’s available capacity in bytes.
    nonisolated var availableCapacity: Int? {
        let resourceValues = getVolumeResourceValues(for: .volumeAvailableCapacityKey)
        return resourceValues?.volumeAvailableCapacity
    }

    /// Volume’s available capacity in bytes for storing important resources.
    ///
    /// Indicates the amount of space that can be made available  for things the user has explicitly requested in the app's UI (i.e. downloading a video or new level for a game.)
    /// If you need more space than what's available - let user know the request cannot be fulfilled.
    nonisolated var availableCapacityForImportantUsage: Int? {
        let resourceValues = getVolumeResourceValues(for: .volumeAvailableCapacityForImportantUsageKey)
        if let result = resourceValues?.volumeAvailableCapacityForImportantUsage {
            return Int(exactly: result)
        } else {
            return nil
        }
    }

    /// Volume’s available capacity in bytes for storing nonessential resources.
    ///
    /// Indicates the amount of space available for things that the user is likely to want but hasn't explicitly requested (i.e. next episode in video series they're watching, or recently updated documents in a server that they might be likely to open.)
    /// For these types of files you might store them initially in the caches directory until they are actually used, at which point you can move them in app support or documents directory.
    nonisolated var availableCapacityForOpportunisticUsage: Int? {
        let resourceValues = getVolumeResourceValues(for: .volumeAvailableCapacityForOpportunisticUsageKey)
        if let result = resourceValues?.volumeAvailableCapacityForOpportunisticUsage {
            return Int(exactly: result)
        } else {
            return nil
        }
    }
}

// MARK: - Utils & Helpers
extension SimplySaveClient {
    /// Helper method to query against a resource value key
    nonisolated func getVolumeResourceValues(for key: URLResourceKey) -> URLResourceValues? {
        let fileUrl = URL(fileURLWithPath: "/")
        let results = try? fileUrl.resourceValues(forKeys: [key])
        return results
    }

    /// Create and returns a URL constructed from specified directory/path
    func createURL(for path: String?, in directory: DirectoryEndpoint) throws -> URL {
        let filePrefix = "file://"
        var validPath: String? = nil
        if let path = path {
            do {
                validPath = try getValidFilePath(from: path)
            } catch {
                throw error
            }
        }

        guard var finalUrl = directory.toSearchPathDirectoryURL else {
            throw SPSDomainError.couldNotAccessUserDomainMask
                .createEnhancedError(
                    description: "Could not create URL for \(directory.pathDescription)/\(validPath ?? "")",
                    failureReason: "Could not get access to the file system's user domain mask.",
                    recoverySuggestion: "Use a different directory."
                )
        }

        if let validPath = validPath {
            finalUrl = finalUrl.appendingPathComponent(validPath, isDirectory: false)
        }
        if finalUrl.absoluteString.lowercased().prefix(filePrefix.count) != filePrefix {
            let fixedUrlString = filePrefix + finalUrl.absoluteString
            finalUrl = URL(string: fixedUrlString)!
        }
        return finalUrl
    }

    /// Create necessary sub folders before creating a file
    func createSubfoldersBeforeCreatingFile(at url: URL) throws {
        let subfolderUrl = url.deletingLastPathComponent()
        var isDirectory: ObjCBool = false
        FileManager.default.fileExists(atPath: subfolderUrl.path, isDirectory: &isDirectory)
        guard !isDirectory.boolValue else {
            return
        }
        try FileManager.default.createDirectory(at: subfolderUrl,
                                                withIntermediateDirectories: true,
                                                attributes: nil)
    }

    /// Find an existing file's URL or throw an error if it doesn't exist
    func getExistingFileURL(for path: String?, in directory: DirectoryEndpoint) throws -> URL {
        let url = try createURL(for: path, in: directory)
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw SPSDomainError.noFileFound
                .createEnhancedError(
                    description: "Could not find an existing file or folder at \(url.path).",
                    failureReason: "There is no existing file or folder at \(url.path)",
                    recoverySuggestion: "Check if a file or folder exists before trying to commit an operation on it."
                )
        }
        return url
    }

    /// Convert a user generated name to a valid file name
    func getValidFilePath(from originalString: String) throws -> String {
        var invalidCharacters = CharacterSet(charactersIn: ":")
        invalidCharacters.formUnion(.newlines)
        invalidCharacters.formUnion(.illegalCharacters)
        invalidCharacters.formUnion(.controlCharacters)
        let pathWithoutIllegalCharacters = originalString
            .components(separatedBy: invalidCharacters)
            .joined(separator: "")
        let validFileName = pathWithoutIllegalCharacters.removeSlashesAtBeginning
        guard !validFileName.isEmpty, validFileName != "." else {
            throw SPSDomainError.invalidFileName
                .createEnhancedError(
                    description: "\(originalString) is an invalid file name.",
                    failureReason: "Cannot write/read a file with the name \(originalString) on disk.",
                    recoverySuggestion: "Use another file name with alphanumeric characters."
                )
        }
        return validFileName
    }

    /// Set 'isExcludedFromBackup' BOOL property of a file or directory in the file system
    func setIsExcludedFromBackup(to isExcludedFromBackup: Bool, for path: String?, in directory: DirectoryEndpoint) throws {
        var resourceUrl = try getExistingFileURL(for: path, in: directory)
        var resourceValues = URLResourceValues()
        resourceValues.isExcludedFromBackup = isExcludedFromBackup
        try resourceUrl.setResourceValues(resourceValues)
    }

    /// Set 'isExcludedFromBackup' BOOL property of a file or directory in the file system
    func setIsExcludedFromBackup(to isExcludedFromBackup: Bool, for url: URL) throws {
        var resourceUrl = url
        var resourceValues = URLResourceValues()
        resourceValues.isExcludedFromBackup = isExcludedFromBackup
        try resourceUrl.setResourceValues(resourceValues)
    }

    /// Helper method to create error for when trying to saving Codable structs as multiple files to a folder
    func createInvalidFileNameForStructsError() -> Error {
        return SPSDomainError.invalidFileName
            .createEnhancedError(
                description: "Cannot save/retrieve the Codable struct without a valid file name. Unlike how arrays of UIImages or Data are stored, Codable structs are not saved as multiple files in a folder, but rather as one JSON file. If you already successfully saved Codable struct(s) to your folder name, try retrieving it as a file named 'Folder' instead of as a folder 'Folder/'",
                failureReason: "Disk does not save structs or arrays of structs as multiple files to a folder like it does UIImages or Data.",
                recoverySuggestion: "Save your struct or array of structs as one file that encapsulates all the data (i.e. \"multiple-messages.json\")")
    }

    /// Helper method to create deserialization error for append(:path:directory:) functions
    func createDeserializationErrorForAppendingStructToInvalidType<T>(url: URL, type: T) -> Error {
        return SPSDomainError.deserialization
            .createEnhancedError(
                description: "Could not deserialize the existing data at \(url.path) to a valid type to append to.",
                failureReason: "JSONDecoder could not decode type \(T.self) from the data existing at the file location.",
                recoverySuggestion: "Ensure that you only append data structure(s) with the same type as the data existing at the file location.")
    }
}
