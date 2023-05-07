//
//  DirectoryEndpoint.swift
//  
//
//  Created by Martin Lukacs on 01/05/2023.
//

import Foundation

public enum DirectoryEndpoint: Equatable {
    /// Only documents and other data that is user-generated, or that cannot otherwise be recreated by your application, should be stored in the <Application_Home>/Documents directory.
    /// Files in this directory are automatically backed up by iCloud. To disable this feature for a specific file, use the .doNotBackup(:in:) method.
    case documents

    /// Data that can be downloaded again or regenerated should be stored in the <Application_Home>/Library/Caches directory. Examples of files you should put in the Caches directory include database cache files and downloadable content, such as that used by magazine, newspaper, and map applications.
    /// Use this directory to write any application-specific support files that you want to persist between launches of the application or during application updates. Your application is generally responsible for adding and removing these files. It should also be able to re-create these files as needed because iTunes removes them during a full restoration of the device. In iOS 2.2 and later, the contents of this directory are not backed up by iTunes.
    /// Note that the system may delete the Caches/ directory to free up disk space, so your app must be able to re-create or download these files as needed.
    case caches

    /// Put app-created support files in the <Application_Home>/Library/Application support directory. In general, this directory includes files that the app uses to run but that should remain hidden from the user. This directory can also include data files, configuration files, templates and modified versions of resources loaded from the app bundle.
    /// Files in this directory are automatically backed up by iCloud. To disable this feature for a specific file, use the .doNotBackup(:in:) method.
    case applicationSupport

    /// Data that is used only temporarily should be stored in the <Application_Home>/tmp directory. Although these files are not backed up to iCloud, remember to delete those files when you are done with them so that they do not continue to consume space on the user’s device.
    /// The system will periodically purge these files when your app is not running; therefore, you cannot rely on these files persisting after your app terminates.
    case temporary

    /// Sandboxed apps that need to share files with other apps from the same developer on a given device can use a shared container along with the com.apple.security.application-groups entitlement.
    /// The shared container or "app group" identifier string is used to locate the corresponding group's shared directory.
    /// For more details, visit https://developer.apple.com/documentation/foundation/nsfilemanager/1412643-containerurlforsecurityapplicati
    case sharedContainer(appGroupName: String)

    public var pathDescription: String {
        switch self {
        case .documents: return "<Application_Home>/Documents"
        case .caches: return "<Application_Home>/Library/Caches"
        case .applicationSupport: return "<Application_Home>/Library/Application"
        case .temporary: return "<Application_Home>/tmp"
        case .sharedContainer(let appGroupName): return "\(appGroupName)"
        }
    }

    static public func ==(lhs: DirectoryEndpoint, rhs: DirectoryEndpoint) -> Bool {
        switch (lhs, rhs) {
        case (.documents, .documents), (.caches, .caches), (.applicationSupport, .applicationSupport), (.temporary, .temporary):
            return true
        case (let .sharedContainer(appGroupName: name1), let .sharedContainer(appGroupName: name2)):
            return name1 == name2
        default:
            return false
        }
    }

    var toSearchPathDirectoryURL: URL? {
        switch self {
        case .documents:
            return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        case .caches:
            return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
        case .applicationSupport:
            return FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        case .temporary:
            return URL(string: NSTemporaryDirectory())
        case .sharedContainer(let appGroupName):
            return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupName)
        }
    }
}
