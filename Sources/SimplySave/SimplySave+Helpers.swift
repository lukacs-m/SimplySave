//
//  SimplySave+Helpers.swift
//  
//
//  Created by Martin Lukacs on 03/05/2023.
//

import Foundation

public extension SimplySaveClient {

    /// Construct URL for a potentially existing or non-existent file (Note: replaces `getURL(for:in:)` which would throw an error if file does not exist)
    ///
    /// - Parameters:
    ///   - path: path of file relative to directory (set nil for entire directory)
    ///   - directory: directory for the specified path
    /// - Returns: URL for either an existing or non-existing file
    /// - Throws: Error if URL creation failed
    func url(for path: String?, in directory: DirectoryEndpoint) throws -> URL {
        let url = try createURL(for: path, in: directory)
        return url
    }

    /// Clear directory by removing all files
    ///
    /// - Parameter directory: directory to clear
    /// - Throws: Error if FileManager cannot access a directory
    func clear(_ directory: DirectoryEndpoint) throws {
        let url = try createURL(for: nil, in: directory)
        let contents = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: [])
        for fileUrl in contents {
            try? FileManager.default.removeItem(at: fileUrl)
        }
    }

    /// Remove file from the file system
    ///
    /// - Parameters:
    ///   - path: path of file relative to directory
    ///   - directory: directory where file is located
    /// - Throws: Error if file could not be removed
    func remove(_ path: String, from directory: DirectoryEndpoint) throws {
        let url = try getExistingFileURL(for: path, in: directory)
        try FileManager.default.removeItem(at: url)
    }

    /// Remove file from the file system
    ///
    /// - Parameters:
    ///   - url: URL of file in filesystem
    /// - Throws: Error if file could not be removed
    func remove(_ url: URL) throws {
        try FileManager.default.removeItem(at: url)
    }

    /// Checks if a file exists
    ///
    /// - Parameters:
    ///   - path: path of file relative to directory
    ///   - directory: directory where file is located
    /// - Returns: Bool indicating whether file exists
    func exists(_ path: String, in directory: DirectoryEndpoint) -> Bool {
        guard let _ = try? getExistingFileURL(for: path, in: directory) else {
            return false
        }
        return true
    }

    /// Checks if a file exists
    ///
    /// - Parameters:
    ///   - url: URL of file in filesystem
    /// - Returns: Bool indicating whether file exists
    func exists(_ url: URL) -> Bool {
        guard FileManager.default.fileExists(atPath: url.path) else {
            return false
        }
        return true
    }


    /// Sets the 'do not backup' attribute of the file or folder on disk to true. This ensures that the file holding the object data does not get deleted when the user's device has low storage, but prevents this file from being stored in any backups made of the device on iTunes or iCloud.
    /// This is only useful for excluding cache and other application support files which are not needed in a backup. Some operations commonly made to user documents will cause the 'do not backup' property to be reset to false and so this should not be used on user documents.
    /// Warning: You must ensure that you will purge and handle any files created with this attribute appropriately, as these files will persist on the user's disk even in low storage situtations. If you don't handle these files appropriately, then you aren't following Apple's file system guidlines and can face App Store rejection.
    /// Ideally, you should let iOS handle deletion of files in low storage situations, and you yourself handle missing files appropriately (i.e. retrieving an image from the web again if it does not exist on disk anymore.)
    ///
    /// - Parameters:
    ///   - path: path of file relative to directory
    ///   - directory: directory where file is located
    /// - Throws: Error if file could not set its 'isExcludedFromBackup' property
    func doNotBackup(for path: String, in directory: DirectoryEndpoint) throws {
        try setIsExcludedFromBackup(to: true, for: path, in: directory)
    }


    /// Sets the 'do not backup' attribute of the file or folder on disk to true. This ensures that the file holding the object data does not get deleted when the user's device has low storage, but prevents this file from being stored in any backups made of the device on iTunes or iCloud.
    /// This is only useful for excluding cache and other application support files which are not needed in a backup. Some operations commonly made to user documents will cause the 'do not backup' property to be reset to false and so this should not be used on user documents.
    /// Warning: You must ensure that you will purge and handle any files created with this attribute appropriately, as these files will persist on the user's disk even in low storage situtations. If you don't handle these files appropriately, then you aren't following Apple's file system guidlines and can face App Store rejection.
    /// Ideally, you should let iOS handle deletion of files in low storage situations, and you yourself handle missing files appropriately (i.e. retrieving an image from the web again if it does not exist on disk anymore.)
    ///
    /// - Parameters:
    ///   - url: URL of file in filesystem
    /// - Throws: Error if file could not set its 'isExcludedFromBackup' property
    func doNotBackup(_ url: URL) throws {
        try setIsExcludedFromBackup(to: true, for: url)
    }

    /// Sets the 'do not backup' attribute of the file or folder on disk to false. This is the default behaviour so you don't have to use this function unless you already called doNotBackup(name:directory:) on a specific file.
    /// This default backing up behaviour allows anything in the .documents and .caches directories to be stored in backups made of the user's device (on iCloud or iTunes)
    ///
    /// - Parameters:
    ///   - path: path of file relative to directory
    ///   - directory: directory where file is located
    /// - Throws: Error if file could not set its 'isExcludedFromBackup' property
    func backup(_ path: String, in directory: DirectoryEndpoint) throws {
        try setIsExcludedFromBackup(to: false, for: path, in: directory)
    }


    /// Sets the 'do not backup' attribute of the file or folder on disk to false. This is the default behaviour so you don't have to use this function unless you already called doNotBackup(name:directory:) on a specific file.
    /// This default backing up behaviour allows anything in the .documents and .caches directories to be stored in backups made of the user's device (on iCloud or iTunes)
    ///
    /// - Parameters:
    ///   - url: URL of file in filesystem
    /// - Throws: Error if file could not set its 'isExcludedFromBackup' property
    func backup(_ url: URL) throws {
        try setIsExcludedFromBackup(to: false, for: url)
    }

    /// Move file to a new directory
    ///
    /// - Parameters:
    ///   - path: path of file relative to directory
    ///   - directory: directory the file is currently in
    ///   - newDirectory: new directory to store file in
    /// - Throws: Error if file could not be moved
    func move(_ path: String, from directory: DirectoryEndpoint, to newDirectory: DirectoryEndpoint) throws {
        let currentUrl = try getExistingFileURL(for: path, in: directory)
        let justDirectoryPath = try createURL(for: nil, in: directory).absoluteString
        let filePath = currentUrl.absoluteString.replacingOccurrences(of: justDirectoryPath, with: "")
        let newUrl = try createURL(for: filePath, in: newDirectory)
        try createSubfoldersBeforeCreatingFile(at: newUrl)
        try FileManager.default.moveItem(at: currentUrl, to: newUrl)
    }

    /// Move file to a new directory
    ///
    /// - Parameters:
    ///   - path: path of file relative to directory
    ///   - directory: directory the file is currently in
    ///   - newDirectory: new directory to store file in
    /// - Throws: Error if file could not be moved
    func move(from originalURL: URL, to newURL: URL) throws {
        try createSubfoldersBeforeCreatingFile(at: newURL)
        try FileManager.default.moveItem(at: originalURL, to: newURL)
    }

    /// Copy file to a new directory
    ///
    /// - Parameters:
    ///   - path: path of file relative to directory
    ///   - directory: directory the file is currently in
    ///   - newFilePath: path to the new copy
    ///   - newDirectory: new directory to copy file in
    /// - Throws: Error if file could not be copied
    func copy(from path: String, in directory: DirectoryEndpoint, to newFilePath: String, and newDirectory: DirectoryEndpoint) throws {
        let currentUrl = try getExistingFileURL(for: path, in: directory)
        let newUrl = try createURL(for: newFilePath, in: newDirectory)
        try createSubfoldersBeforeCreatingFile(at: newUrl)
        try FileManager.default.copyItem(at: currentUrl, to: newUrl)
    }

    /// Copy file to a new directory
    ///
    /// - Parameters:
    ///   - originalURL: url of file
    ///   - newURL: new url for the copy
    /// - Throws: Error if file could not be moved
    func copy(from originalURL: URL, to newURL: URL) throws {
        try createSubfoldersBeforeCreatingFile(at: newURL)
        try FileManager.default.copyItem(at: originalURL, to: newURL)
    }

    /// Rename a file
    ///
    /// - Parameters:
    ///   - path: path of file relative to directory
    ///   - directory: directory the file is in
    ///   - newName: new name to give to file
    /// - Throws: Error if object could not be renamed
    func rename(_ path: String, from directory: DirectoryEndpoint, to newPath: String) throws {
        let currentUrl = try getExistingFileURL(for: path, in: directory)
        let justDirectoryPath = try createURL(for: nil, in: directory).absoluteString
        var currentFilePath = currentUrl.absoluteString.replacingOccurrences(of: justDirectoryPath, with: "")
        if isFolder(currentUrl) && currentFilePath.suffix(1) != "/" {
            currentFilePath = currentFilePath + "/"
        }
        let currentValidFilePath = try getValidFilePath(from: path)
        let newValidFilePath = try getValidFilePath(from: newPath)
        let newFilePath = currentFilePath.replacingOccurrences(of: currentValidFilePath, with: newValidFilePath)
        let newUrl = try createURL(for: newFilePath, in: directory)
        try createSubfoldersBeforeCreatingFile(at: newUrl)
        try FileManager.default.moveItem(at: currentUrl, to: newUrl)
    }

    /// Check if file at a URL is a folder
    func isFolder(_ url: URL) -> Bool {
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory), isDirectory.boolValue else {
            return false
        }
        return true
    }
}
