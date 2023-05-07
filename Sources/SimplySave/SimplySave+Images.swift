//
//  SimplySave+Images.swift
//  
//
//  Created by Martin Lukacs on 03/05/2023.
//

import Foundation
import UIKit

// MARK: - Image
public extension SimplySaveClient {

    /// Save image to disk
    ///
    /// - Parameters:
    ///   - value: image to store to disk
    ///   - directory: user directory to store the image file in
    ///   - path: file location to store the data (i.e. "Folder/file.png")
    /// - Throws: Error if there were any issues writing the image to disk
    @discardableResult
    func save(_ value: UIImage, as path: String, in directory: DirectoryEndpoint) throws -> URL {
        guard let imageData = value.pngData() ?? value.jpegData(compressionQuality: 1) else {
            throw SPSDomainError.serialization
                .createEnhancedError(description: "Could not serialize UIImage to Data.",
                                     failureReason: "UIImage could not serialize to PNG or JPEG data.",
                                     recoverySuggestion: "Make sure image is not corrupt or try saving without an extension at all.")
        }
        let url = try createURL(for: path, in: directory)
        try createSubfoldersBeforeCreatingFile(at: url)
        try imageData.write(to: url, options: .atomic)
        return url
    }


    /// Save an array of images to disk
    ///
    /// - Parameters:
    ///   - value: array of images to store
    ///   - directory: user directory to store the images in
    ///   - path: folder location to store the images (i.e. "Folder/")
    /// - Throws: Error if there were any issues creating a folder and writing the given images to it
    @discardableResult
    func save(_ value: [UIImage], as path: String, in directory: DirectoryEndpoint) throws -> [URL] {
        let folderUrl = try createURL(for: path, in: directory)
        try createSubfoldersBeforeCreatingFile(at: folderUrl)
        try FileManager.default.createDirectory(at: folderUrl, withIntermediateDirectories: false, attributes: nil)

        var urls: [URL] = []
        for i in 0..<value.count {
            let image = value[i]
            let imageName = "\(i)"
            guard let imageData = image.computeDataAndName(with: "\(imageName)") else {
                throw  SPSDomainError.serialization
                    .createEnhancedError(description: "Could not serialize UIImage \(i) in the array to Data.",
                                            failureReason: "UIImage \(i) could not serialize to PNG or JPEG data.",
                                            recoverySuggestion: "Make sure there are no corrupt images in the array.")
            }
            let imageUrl = folderUrl.appendingPathComponent(imageData.name, isDirectory: false)
            try imageData.data.write(to: imageUrl, options: .atomic)
            urls.append(imageUrl)
        }
        return urls
    }

    /// Retrieve image from disk
    ///
    /// - Parameters:
    ///   - path: path where image is stored
    ///   - directory: user directory to retrieve the image file from
    ///   - type: here for Swifty generics magic, use UIImage.self
    /// - Returns: UIImage from disk
    /// - Throws: Error if there were any issues retrieving the specified image
    func fetch(from path: String, in directory: DirectoryEndpoint) throws -> UIImage {
        let url = try getExistingFileURL(for: path, in: directory)
        let data = try Data(contentsOf: url)

        guard let image = UIImage(data: data) else {
            throw SPSDomainError.deserialization
                .createEnhancedError(
                    description: "Could not decode UIImage from \(url.path).",
                    failureReason: "A UIImage could not be created out of the data in \(url.path).",
                    recoverySuggestion: "Try deserializing \(url.path) manually after retrieving it as Data."
                )
        }
        return image
    }

    /// Retrieve an array of images from a folder on disk
    ///
    /// - Parameters:
    ///   - path: path of folder holding desired images
    ///   - directory: user directory where images' folder was created
    ///   - type: here for Swifty generics magic, use [UIImage].self
    /// - Returns: [UIImage] from disk
    /// - Throws: Error if there were any issues retrieving the specified folder of images
    func fetch(from path: String, in directory: DirectoryEndpoint) throws -> [UIImage] {
        let url = try getExistingFileURL(for: path, in: directory)
        let fileUrls = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: [])

        let images = try fileUrls.sorted { (url1, url2) -> Bool in
            if let fileNameInt1 = url1.fileNameToInt, let fileNameInt2 = url2.fileNameToInt {
                return fileNameInt1 <= fileNameInt2
            }
            return true
        }.compactMap {
            let data = try Data(contentsOf: $0)
            return UIImage(data: data)
        }
        return images
    }

    /// Append an image to a folder
    ///
    /// - Parameters:
    ///   - value: image to store to disk
    ///   - path: folder location to store the image (i.e. "Folder/")
    ///   - directory: user directory to store the image file in
    /// - Throws: Error if there were any issues writing the image to disk
    func append(_ value: UIImage, to path: String, in directory: DirectoryEndpoint) throws {
        guard let folderUrl = try? getExistingFileURL(for: path, in: directory) else {
            let array = [value]
            try save(array, as: path, in: directory)
            return
        }

        let fileUrls = try FileManager.default.contentsOfDirectory(at: folderUrl, includingPropertiesForKeys: nil, options: [])
        let largestFileNameInt = fileUrls
            .compactMap { $0.fileNameToInt }
            .max() ?? -1

        let newFileNameInt = largestFileNameInt + 1
        guard let imageData = value.computeDataAndName(with: "\(newFileNameInt)") else {
            throw SPSDomainError.serialization
                .createEnhancedError(
                description: "Could not serialize UIImage to Data.",
                failureReason: "UIImage could not serialize to PNG or JPEG data.",
                recoverySuggestion: "Make sure image is not corrupt."
            )
        }
        let imageUrl = folderUrl.appendingPathComponent(imageData.name, isDirectory: false)
        try imageData.data.write(to: imageUrl, options: .atomic)
    }

    /// Append an array of images to a folder
    ///
    /// - Parameters:
    ///   - value: images to store to disk
    ///   - path: folder location to store the images (i.e. "Folder/")
    ///   - directory: user directory to store the images in
    /// - Throws: Error if there were any issues writing the images to disk
     func append(_ value: [UIImage], to path: String, in directory: DirectoryEndpoint) throws {
         guard let _ = try? getExistingFileURL(for: path, in: directory) else {
             try save(value, as: path, in: directory)
             return
         }
         for image in value {
             try append(image, to: path, in: directory)
         }
    }
}
