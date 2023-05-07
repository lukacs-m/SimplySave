//
//  SimplySave+Data.swift
//  
//
//  Created by Martin Lukacs on 03/05/2023.
//

import Foundation

// MARK: - Data
public extension SimplySaveClient {
    /// Save Data to disk
    ///
    /// - Parameters:
    ///   - value: Data to store to disk
    ///   - path: file location to store the data (i.e. "Folder/file.mp4")
    ///   - directory: user directory to store the file in
    /// - Throws: Error if there were any issues writing the given data to disk
    @discardableResult
    func save(_ value: Data, as path: String, in directory: DirectoryEndpoint) async throws -> URL {
        let url = try createURL(for: path, in: directory)
        try createSubfoldersBeforeCreatingFile(at: url)
        try value.write(to: url, options: .atomic)
        return url
    }

    /// Save an array of Data objects to disk
    ///
    /// - Parameters:
    ///   - value: array of Data to store to disk
    ///   - path: folder location to store the data files (i.e. "Folder/")
    ///   - directory: user directory to store the files in
    /// - Throws: Error if there were any issues creating a folder and writing the given [Data] to files in it
    @discardableResult
    func save(_ value: [Data], as path: String, in directory: DirectoryEndpoint) async throws -> [URL] {
        let folderUrl = try createURL(for: path, in: directory)
        try createSubfoldersBeforeCreatingFile(at: folderUrl)
        try FileManager.default.createDirectory(at: folderUrl, withIntermediateDirectories: false, attributes: nil)
        var urls: [URL] = []
        for i in 0..<value.count {
            let data = value[i]
            let dataName = "\(i)"
            let dataUrl = folderUrl.appendingPathComponent(dataName, isDirectory: false)
            try data.write(to: dataUrl, options: .atomic)
            urls.append(dataUrl)
        }
        return urls
    }

    /// Retrieve data from disk
    ///
    /// - Parameters:
    ///   - path: path where data file is stored
    ///   - directory: user directory to retrieve the file from
    ///   - type: here for Swifty generics magic, use Data.self
    /// - Returns: Data retrieved from disk
    /// - Throws: Error if there were any issues retrieving the specified file's data
    func fetch(from path: String, in directory: DirectoryEndpoint) async throws -> Data {
        let url = try getExistingFileURL(for: path, in: directory)
        let data = try Data(contentsOf: url)
        return data
    }

    /// Retrieve an array of Data objects from disk
    ///
    /// - Parameters:
    ///   - path: path of folder that's holding the Data objects' files
    ///   - directory: user directory where folder was created for holding Data objects
    /// - Returns: [Data] from disk
    /// - Throws: Error if there were any issues retrieving the specified folder of files
    func fetch(from path: String, in directory: DirectoryEndpoint) throws -> [Data] {
        let url = try getExistingFileURL(for: path, in: directory)
        let fileUrls = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: [])
        let dataObjects = try fileUrls.sorted { (url1, url2) -> Bool in
            guard let fileNameInt1 = url1.fileNameToInt, let fileNameInt2 = url2.fileNameToInt else {
                return true
            }
            return fileNameInt1 <= fileNameInt2
        }.map { try Data(contentsOf: $0) }
        return dataObjects
    }

    /// Append a file with Data to a folder
    ///
    /// - Parameters:
    ///   - value: Data to store to disk
    ///   - directory: user directory to store the file in
    ///   - path: folder location to store the data files (i.e. "Folder/")
    /// - Throws: Error if there were any issues writing the given data to disk
    func append(_ value: Data, to path: String, in directory: DirectoryEndpoint) async throws {
        guard let folderUrl = try? getExistingFileURL(for: path, in: directory) else {
            try await save([value], as: path, in: directory)
            return
        }
        let fileUrls = try FileManager.default.contentsOfDirectory(at: folderUrl, includingPropertiesForKeys: nil, options: [])
        let largestFileNameInt = fileUrls
            .compactMap { $0.fileNameToInt }
            .max() ?? -1
        let newFileNameInt = largestFileNameInt + 1
        let dataUrl = folderUrl.appendingPathComponent("\(newFileNameInt)", isDirectory: false)
        try value.write(to: dataUrl, options: .atomic)
    }


    /// Append an array of data objects as files to a folder
    ///
    /// - Parameters:
    ///   - value: array of Data to store to disk
    ///   - directory: user directory to create folder with data objects
    ///   - path: folder location to store the data files (i.e. "Folder/")
    /// - Throws: Error if there were any issues writing the given Data
    func append(_ value: [Data], to path: String, in directory: DirectoryEndpoint) async throws {
        guard let _ = try? getExistingFileURL(for: path, in: directory) else {
            try await save(value, as: path, in: directory)
            return
        }
        for data in value {
            try await append(data, to: path, in: directory)
        }
    }
}
