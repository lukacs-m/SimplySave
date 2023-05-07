//
//  SimpleSaving.swift
//  
//
//  Created by Martin Lukacs on 04/05/2023.
//

import Foundation
import UIKit

public protocol SimpleSaving {
    var totalCapacity: Int? { get }
    var availableCapacity: Int? { get }
    var availableCapacityForImportantUsage: Int? { get }
    var availableCapacityForOpportunisticUsage: Int? { get }

    // MARK: - Codable objects
    @discardableResult
    func save<Entity: Encodable>(_ value: Entity,
                                 as path: String,
                                 in directory: DirectoryEndpoint) async throws -> URL

    func fetch<Entity: Decodable>(from path: String,
                                  in directory: DirectoryEndpoint) async throws -> Entity
    
    func append<Entity: Codable>(_ value: Entity,
                                 to path: String,
                                 in directory: DirectoryEndpoint) async throws
    func append<Entity: Codable>(_ value: [Entity],
                                 to path: String,
                                 in directory: DirectoryEndpoint) async throws

    // MARK: - Data
    @discardableResult
    func save(_ value: Data, as path: String, in directory: DirectoryEndpoint) async throws -> URL
    @discardableResult
    func save(_ value: [Data], as path: String, in directory: DirectoryEndpoint) async throws -> [URL]
    func fetch(from path: String, in directory: DirectoryEndpoint) async throws -> Data
    func fetch(from path: String, in directory: DirectoryEndpoint) async throws -> [Data]
    func append(_ value: Data, to path: String, in directory: DirectoryEndpoint) async throws
    func append(_ value: [Data], to path: String, in directory: DirectoryEndpoint) async throws

    // MARK: - Images
    @discardableResult
    func save(_ value: UIImage, as path: String, in directory: DirectoryEndpoint) async throws -> URL
    @discardableResult
    func save(_ value: [UIImage], as path: String, in directory: DirectoryEndpoint) async throws -> [URL]
    func fetch(from path: String, in directory: DirectoryEndpoint) async throws -> UIImage
    func fetch(from path: String, in directory: DirectoryEndpoint) async throws -> [UIImage]
    func append(_ value: UIImage, to path: String, in directory: DirectoryEndpoint) async throws 
    func append(_ value: [UIImage], to path: String, in directory: DirectoryEndpoint) async throws

    // MARK: - Helpers
    func url(for path: String?, in directory: DirectoryEndpoint) async throws -> URL
    func clear(_ directory: DirectoryEndpoint) async throws
    func remove(_ path: String, from directory: DirectoryEndpoint) async throws
    func remove(_ url: URL) async throws
    func exists(_ path: String, in directory: DirectoryEndpoint) async ->  Bool
    func exists(_ url: URL) async -> Bool
    func doNotBackup(for path: String, in directory: DirectoryEndpoint) async throws
    func doNotBackup(_ url: URL) async throws
    func backup(_ path: String, in directory: DirectoryEndpoint) async throws
    func backup(_ url: URL) async throws
    func move(_ path: String, from directory: DirectoryEndpoint, to newDirectory: DirectoryEndpoint) async throws
    func move(from originalURL: URL, to newURL: URL) async throws
    func copy(from path: String, in directory: DirectoryEndpoint, to newFilePath: String, and newDirectory: DirectoryEndpoint) async throws
    func copy(from originalURL: URL, to newURL: URL) async throws
    func rename(_ path: String, from directory: DirectoryEndpoint, to newPath: String) async throws
    func isFolder(_ url: URL) async ->  Bool
}
