import XCTest
import SwiftUI
import UIKit
import SimplySave

final class SimplySaveTests: XCTestCase {

    let sut: SimpleSaving = SimplySaveClient()
    // MARK: Helpers

    // Convert Error -> String of descriptions
    func convertErrorToString(_ error: Error) -> String {
        return """
        Domain: \((error as NSError).domain)
        Code: \((error as NSError).code)
        Description: \(error.localizedDescription)
        Failure Reason: \((error as NSError).localizedFailureReason ?? "nil")
        Suggestions: \((error as NSError).localizedRecoverySuggestion ?? "nil")\n
        """
    }

    var images = [UIImage]()

    override func setUp() {
        super.setUp()

        if let path = Bundle.module.path(forResource:  "curiosity", ofType: "jpeg"),
           let image = UIImage(contentsOfFile: path) {
            images.append(image)
        }
        if let path = Bundle.module.path(forResource:  "oppertunity", ofType: "jpeg"),
           let image = UIImage(contentsOfFile: path) {
            images.append(image)
        }
        if let path = Bundle.module.path(forResource:  "spirit", ofType: "jpeg"),
           let image = UIImage(contentsOfFile: path) {
            images.append(image)
        }
    }

    // We'll clear out all our directories after each test
    override func tearDown()  {
        Task {
            do {
                try await sut.clear(.documents)
                try await sut.clear(.caches)
                try await sut.clear(.applicationSupport)
                try await sut.clear(.temporary)
            } catch {
                // NOTE: If you get a NSCocoaErrorDomain with code 260, this means one of the above directories could not be found.
                // On some of the newer simulators, not all these default directories are initialized at first, but will be created
                // after you save something within it. To fix this, run each of the test[directory] test functions below to get each
                // respective directory initialized, before running other tests.
                fatalError(convertErrorToString(error))
            }
        }
    }

    // MARK: Dummmy data

    let messages: [Message] = {
        var array = [Message]()
        for i in 1...10 {
            let element = Message(title: "Message \(i)", body: "...")
            array.append(element)
        }
        return array
    }()



    lazy var data: [Data] = self.images.compactMap { $0.pngData() }

    // MARK: Tests

    func testSaveStructs() async throws {
        // 1 struct
        try await sut.save(messages[0], as: "message.json", in: .documents)
        let result1 = await sut.exists("message.json", in: .documents)
        XCTAssertTrue(result1)
        let messageUrl = try await sut.url(for: "message.json", in: .documents)
        print("A message was saved as \(messageUrl.absoluteString)")
        let retrievedMessage: Message = try await sut.fetch(from: "message.json", in: .documents)
        XCTAssert(messages[0] == retrievedMessage)

        // ... in folder hierarchy
        try await sut.save(messages[0], as: "Messages/Bob/message.json", in: .documents)
        let result2 = await sut.exists("Messages/Bob/message.json", in: .documents)
        XCTAssertTrue(result2)
        let messageInFolderUrl = try await sut.url(for: "Messages/Bob/message.json", in: .documents)
        print("A message was saved as \(messageInFolderUrl.absoluteString)")
        let retrievedMessageInFolder: Message = try await sut.fetch(from: "Messages/Bob/message.json", in: .documents)
        XCTAssert(messages[0] == retrievedMessageInFolder)

        // Array of structs
        try await sut.save(messages, as: "messages.json", in: .documents)
        let result3 = await sut.exists("message.json", in: .documents)
        XCTAssertTrue(result3)
        let messagesUrl = try await sut.url(for: "messages.json", in: .documents)
        print("Messages were saved as \(messagesUrl.absoluteString)")
        let retrievedMessages: [Message] = try await sut.fetch(from: "messages.json", in: .documents)
        XCTAssert(messages == retrievedMessages)
    }

    func testAppendStructs() async throws {
        // Append a single struct to an empty location
        try await sut.append(messages[0], to: "single-message.json", in: .documents)
        let retrievedSingleMessage: [Message] = try await sut.fetch(from: "single-message.json", in: .documents)
        let results1 = await sut.exists("single-message.json", in: .documents)
        XCTAssertTrue(results1)
        XCTAssertEqual(retrievedSingleMessage[0], messages[0])

        // Append an array of structs to an empty location
        try await sut.append(messages, to: "multiple-messages.json", in: .documents)
        let retrievedMultipleMessages: [Message] = try await sut.fetch(from: "multiple-messages.json", in: .documents)
        let results2 = await sut.exists("multiple-messages.json", in: .documents)
        XCTAssert(results2)
        XCTAssert(retrievedMultipleMessages == messages)

        // Append a single struct to a single struct
        try await sut.save(messages[0], as: "messages.json", in: .documents)
        let results3 = await sut.exists("messages.json", in: .documents)
        XCTAssert(results3)
        try await sut.append(messages[1], to: "messages.json", in: .documents)
        let retrievedMessages: [Message] = try await sut.fetch(from: "messages.json", in: .documents)
        XCTAssert(retrievedMessages[0] == messages[0] && retrievedMessages[1] == messages[1])

        // Append an array of structs to a single struct
        try await sut.save(messages[5],  as: "one-message.json", in: .caches)
        try await sut.append(messages, to: "one-message.json", in: .caches)
        let retrievedOneMessage: [Message] = try await sut.fetch(from: "one-message.json", in: .caches)
        XCTAssert(retrievedOneMessage.count == messages.count + 1)
        XCTAssert(retrievedOneMessage[0] == messages[5])
        XCTAssert(retrievedOneMessage.last! == messages.last!)

        // Append a single struct to an array of structs
        try await sut.save(messages, as: "many-messages.json", in: .documents)
        try await sut.append(messages[1], to: "many-messages.json", in: .documents)
        let retrievedManyMessages: [Message] = try await sut.fetch(from: "many-messages.json", in: .documents)
        XCTAssert(retrievedManyMessages.count == messages.count + 1)
        XCTAssert(retrievedManyMessages[0] == messages[0])
        XCTAssert(retrievedManyMessages.last! == messages[1])

        let array = [messages[0], messages[1], messages[2]]
        try await sut.save(array, as: "a-few-messages.json", in: .documents)
        let results4 = await sut.exists("a-few-messages.json", in: .documents)
        XCTAssertTrue(results4)
        try await sut.append(messages[3], to: "a-few-messages.json", in: .documents)
        let retrievedFewMessages: [Message] = try await sut.fetch(from: "a-few-messages.json", in: .documents)
        XCTAssert(retrievedFewMessages[0] == array[0] && retrievedFewMessages[1] == array[1] && retrievedFewMessages[2] == array[2] && retrievedFewMessages[3] == messages[3])

        // Append an array of structs to an array of structs
        try await sut.save(messages, as: "array-of-structs.json", in: .documents)
        try await sut.append(messages, to: "array-of-structs.json", in: .documents)
        let retrievedArrayOfStructs: [Message] = try await sut.fetch(from: "array-of-structs.json", in: .documents)
        XCTAssert(retrievedArrayOfStructs.count == (messages.count * 2))
        XCTAssert(retrievedArrayOfStructs[0] == messages[0] && retrievedArrayOfStructs.last! == messages.last!)
    }

    func testSaveImages() async throws {
        // 1 image
        try await sut.save(images[0], as: "image.png", in: .documents)
        let doesExist = await sut.exists("image.png", in: .documents)
        XCTAssertTrue(doesExist)
        let imageUrl = try await sut.url(for: "image.png", in: .documents)
        print("An image was saved as \(imageUrl.absoluteString)")
        let retrievedImage: UIImage = try await sut.fetch(from: "image.png", in: .documents)
        XCTAssert(images[0].dataEquals(retrievedImage))

        // ... in folder hierarchy
        try await sut.save(images[0], as: "Photos/image.png", in: .documents)
        let result1 = await sut.exists("Photos/image.png", in: .documents)
        XCTAssert(result1)
        let imageInFolderUrl = try await sut.url(for: "Photos/image.png", in: .documents)
        print("An image was saved as \(imageInFolderUrl.absoluteString)")
        let retrievedInFolderImage: UIImage = try await sut.fetch(from: "Photos/image.png", in: .documents)
        XCTAssert(images[0].dataEquals(retrievedInFolderImage))

        // Array of images
        try await sut.save(images, as: "album/", in: .documents)
        let result2 = await sut.exists("album/", in: .documents)
        XCTAssertTrue(result2)
        let imagesFolderUrl = try await sut.url(for: "album/", in: .documents)
        print("Images were saved as \(imagesFolderUrl.absoluteString)")
        let retrievedImages: [UIImage] = try await sut.fetch(from: "album/", in: .documents)
        for i in 0..<images.count {
            XCTAssert(images[i].dataEquals(retrievedImages[i]))
        }

        // ... in folder hierarchy
        try await sut.save(images, as: "Photos/summer-album/", in: .documents)
        let result3 = await sut.exists("Photos/summer-album/", in: .documents)
        XCTAssertTrue(result3)
        let imagesInFolderUrl = try await sut.url(for: "Photos/summer-album/", in: .documents)
        print("Images were saved as \(imagesInFolderUrl.absoluteString)")
        let retrievedInFolderImages: [UIImage] = try await sut.fetch(from: "Photos/summer-album/", in: .documents)
        for i in 0..<images.count {
            XCTAssert(images[i].dataEquals(retrievedInFolderImages[i]))
        }
    }

    func testAppendImages() async throws {
        // Append a single image to an empty folder
        try await sut.append(images[0], to: "EmptyFolder/", in: .documents)
        let exists1 = await sut.exists("EmptyFolder/0.png", in: .documents)
        XCTAssertTrue(exists1)
        let retrievedImage:[UIImage] = try await sut.fetch(from: "EmptyFolder", in: .documents)
        let exists2 = await sut.exists("EmptyFolder/0.png", in: .documents)
        XCTAssertTrue(exists2)
        XCTAssert(retrievedImage.count == 1)
        XCTAssert(retrievedImage[0].dataEquals(images[0]))

        // Append an array of images to an empty folder
        try await sut.append(images, to: "EmptyFolder2/", in: .documents)
        let exists3 = await sut.exists("EmptyFolder2/0.png", in: .documents)
        XCTAssertTrue(exists3)
        var retrievedImages: [UIImage] = try await sut.fetch(from: "EmptyFolder2", in: .documents)
        XCTAssert(retrievedImages.count == images.count)
        for i in 0..<retrievedImages.count {
            let image = retrievedImages[i]
            XCTAssert(image.dataEquals(images[i]))
        }

        // Append a single image to an existing folder with images
        try await sut.save(images, as: "Folder/", in: .documents)
        let exist4 = await sut.exists("Folder/", in: .documents)
        XCTAssertTrue(exist4)
        try await sut.append(images[1], to: "Folder/", in: .documents)
        retrievedImages = try await sut.fetch(from: "Folder/", in: .documents)
        XCTAssert(retrievedImages.count == images.count + 1)
        let exists5 = await sut.exists("Folder/3.png", in: .documents)
        XCTAssertTrue(exists5)
        XCTAssert(retrievedImages.last!.dataEquals(images[1]))

        // Append an array of images to an existing folder with images
        try await sut.append(images, to: "Folder/", in: .documents)
        retrievedImages = try await sut.fetch(from: "Folder/", in: .documents)
        XCTAssert(retrievedImages.count == images.count * 2 + 1)
        XCTAssert(retrievedImages.last!.dataEquals(images.last!))

    }

    func testSaveData() async throws {
        // 1 data object
        try await sut.save(data[0], as: "file", in: .documents)
        let fileUrl = try await sut.url(for: "file", in: .documents)
        print("A file was saved to \(fileUrl.absoluteString)")
        let retrievedFile: Data = try await sut.fetch(from: "file", in: .documents)
        XCTAssert(data[0] == retrievedFile)

        // ... in folder hierarchy
        try await sut.save(data[0],  as: "Folder/file", in: .documents)
        let fileInFolderUrl = try await sut.url(for: "Folder/file", in: .documents)
        print("A file was saved as \(fileInFolderUrl.absoluteString)")
        let retrievedInFolderFile: Data = try await sut.fetch(from: "Folder/file", in: .documents)
        XCTAssert(data[0] == retrievedInFolderFile)

        // Array of data
        try await sut.save(data, as: "several-files/", in: .documents)
        let folderUrl = try await sut.url(for: "several-files/", in: .documents)
        print("Files were saved to \(folderUrl.absoluteString)")
        let retrievedFiles: [Data] = try await sut.fetch(from: "several-files/", in: .documents)
        XCTAssert(data == retrievedFiles)

        // ... in folder hierarchy
        try await sut.save(data, as: "Folder/Files/", in: .documents)
        let filesInFolderUrl = try await sut.url(for: "Folder/Files/", in: .documents)
        print("Files were saved to \(filesInFolderUrl.absoluteString)")
        let retrievedInFolderFiles: [Data] = try await sut.fetch(from: "Folder/Files/", in: .documents)
        XCTAssert(data == retrievedInFolderFiles)
    }

    func testAppendData() async throws {
        // Append a single data object to an empty folder
        try await sut.append(data[0], to: "EmptyFolder/", in: .documents)
        let retrievedObject: [Data] = try await sut.fetch(from: "EmptyFolder", in: .documents)
        XCTAssert(retrievedObject.count == 1)
        XCTAssert(retrievedObject[0] == data[0])

        // Append an array of data objects to an empty folder
        try await sut.append(data, to: "EmptyFolder2/", in: .documents)
        var retrievedObjects: [Data] = try await sut.fetch(from: "EmptyFolder2", in: .documents)
        XCTAssert(retrievedObjects.count == data.count)
        for i in 0..<retrievedObjects.count {
            let object = retrievedObjects[i]
            XCTAssert(object == data[i])
        }

        // Append a single data object to an existing folder with files
        try await sut.save(data,as: "Folder/", in: .documents )
        try await sut.append(data[1], to: "Folder/", in: .documents)
        retrievedObjects = try await sut.fetch(from: "Folder/", in: .documents)
        XCTAssert(retrievedObjects.count == data.count + 1)
        XCTAssert(retrievedObjects.last! == data[1])

        // Append an array of data objects to an existing folder with files
        try await sut.append(data, to: "Folder/", in: .documents)
        retrievedObjects = try await sut.fetch(from: "Folder/", in: .documents)
        XCTAssert(retrievedObjects.count == data.count * 2 + 1)
        XCTAssert(retrievedObjects.last! == data.last!)

    }

    func testSaveAsDataRetrieveAsImage() async throws {
        // save as data
        let image = images[0]
        let imageData = image.pngData()!
        try await sut.save(imageData, as: "file", in: .documents)
        let fileUrl = try await sut.url(for: "file", in: .documents)
        print("A file was saved to \(fileUrl.absoluteString)")

        // Retrieve as image
        let retrievedFileAsImage: UIImage = try await sut.fetch(from: "file", in: .documents)
        XCTAssert(image.dataEquals(retrievedFileAsImage))

        // Array of data
        let arrayOfImagesData = images.map { $0.pngData()! } // -> [Data]
        try await sut.save(arrayOfImagesData, as: "data-folder/", in: .documents )
        let folderUrl = try await sut.url(for: "data-folder/", in: .documents)
        print("Files were saved to \(folderUrl.absoluteString)")
        // Retrieve the files as [UIImage]
        let retrievedFilesAsImages: [UIImage] = try await sut.fetch(from: "data-folder/", in: .documents)
        for i in 0..<images.count {
            XCTAssert(images[i].dataEquals(retrievedFilesAsImages[i]))
        }

    }

    func testDocuments() async throws {
        try await testForFolder(directoryEndpoint: .documents)
    }

    func testCaches() async throws {
        try await testForFolder(directoryEndpoint: .caches)

    }

    func testApplicationSupport() async throws {
        try await testForFolder(directoryEndpoint: .applicationSupport)
    }

    private func testForFolder(directoryEndpoint: DirectoryEndpoint) async throws {
        // json
        try await sut.save(messages, as: "messages.json", in: directoryEndpoint)
        let exist = await sut.exists("messages.json", in: directoryEndpoint)
        XCTAssertTrue(exist)

        // 1 image
        try await sut.save(images[0], as: "image.png", in: directoryEndpoint)
        let exist7 = await sut.exists("image.png", in: directoryEndpoint)
        XCTAssertTrue(exist7)
        let retrievedImage: UIImage = try await sut.fetch(from: "image.png", in: directoryEndpoint)
        XCTAssert(images[0].dataEquals(retrievedImage))

        // ... in folder hierarchy
        try await sut.save(images[0], as: "Folder1/Folder2/Folder3/image.png", in: directoryEndpoint)
        let exist2 = await sut.exists("Folder1", in: directoryEndpoint)
        let exist3 = await sut.exists("Folder1/Folder2/", in: directoryEndpoint)
        let exist4 = await sut.exists("Folder1/Folder2/Folder3/", in: directoryEndpoint)
        let exist5 = await sut.exists("Folder1/Folder2/Folder3/image.png", in: directoryEndpoint)
        XCTAssertTrue(exist2)
        XCTAssertTrue(exist3)
        XCTAssertTrue(exist4)
        XCTAssertTrue(exist5)
        let retrievedImageInFolders: UIImage = try await sut.fetch(from: "Folder1/Folder2/Folder3/image.png", in: directoryEndpoint)
        XCTAssert(images[0].dataEquals(retrievedImageInFolders))

        // Array of images
        try await sut.save(images, as: "album", in: directoryEndpoint)
        let exist6 = await sut.exists("album", in: directoryEndpoint)
        XCTAssert(exist6)
        let retrievedImages: [UIImage] = try await sut.fetch(from: "album", in: directoryEndpoint)
        for i in 0..<images.count {
            XCTAssert(images[i].dataEquals(retrievedImages[i]))
        }
    }


    func testTemporary() async throws {
        try await testForFolder(directoryEndpoint: .temporary)
    }

    // MARK: Test helper methods

    func testGetUrl() async throws {
        try await sut.clear(.documents)
        // 1 struct
        try await sut.save(messages[0], as: "message.json", in: .documents)
        let messageUrlPath = try await sut.url(for: "message.json", in: .documents).path.replacingOccurrences(of: "file://", with: "")
        XCTAssert(FileManager.default.fileExists(atPath: messageUrlPath))

        // Array of images (folder)
        try await sut.save(images, as: "album", in: .documents )
        let folderUrlPath = try await sut.url(for: "album/", in: .documents).path.replacingOccurrences(of: "file://", with: "")
        var isDirectory: ObjCBool = false
        if FileManager.default.fileExists(atPath: folderUrlPath, isDirectory: &isDirectory) {
            XCTAssert(isDirectory.boolValue)
        } else {
            XCTFail()
        }
    }

    func testClear()  async throws {
        try await sut.save(messages[0], as: "message.json", in: .caches)
        var exist = await sut.exists("message.json", in: .caches)
        XCTAssertTrue(exist)
        try await sut.clear(.caches)
        exist = await sut.exists("message.json", in: .caches)
        XCTAssertFalse(exist)
    }

    func testRemove() async throws {
        try await sut.save(messages[0], as: "message.json", in: .caches)
        var exist = await sut.exists("message.json", in: .caches)
        XCTAssert(exist)
        try await sut.remove("message.json", from: .caches)
        exist = await sut.exists("message.json", in: .caches)
        XCTAssertFalse(exist)

        try await sut.save(messages[0], as: "message2.json", in: .caches)
        var exist2 = await sut.exists("message2.json", in: .caches)
        XCTAssert(exist2)
        let message2Url = try await sut.url(for: "message2.json", in: .caches)
        try await sut.remove(message2Url)
        exist2 = await sut.exists("message2.json", in: .caches)
        XCTAssertFalse(exist2)
        let exist3 = await sut.exists(message2Url)
        XCTAssertFalse(exist3)
    }

    func testExists() async throws {
        try await sut.save(messages[0], as: "message.json", in: .caches)
        let exist = await sut.exists("message.json", in: .caches)
        XCTAssert(exist)
        let messageUrl = try await sut.url(for: "message.json", in: .caches)
        let exist2 = await sut.exists(messageUrl)
        XCTAssert(exist2)

        // folder
        try await sut.save(images,as: "album/", in: .documents)
        let exist3 = await sut.exists("album/", in: .documents)
        XCTAssert(exist3)
        let albumUrl = try await sut.url(for: "album/", in: .documents)
        let exist4 = await sut.exists(albumUrl)
        XCTAssert(exist4)

    }

    func testDoNotBackupAndBackup() async throws  {
        // Do not backup
        try await sut.save(messages[0], as: "Messages/message.json", in: .documents)
        try await sut.doNotBackup(for: "Messages/message.json", in: .documents)
        let messageUrl = try await sut.url(for: "Messages/message.json", in: .documents)
        if let resourceValues = try? messageUrl.resourceValues(forKeys: [.isExcludedFromBackupKey]),
           let isExcludedFromBackup = resourceValues.isExcludedFromBackup {
            XCTAssert(isExcludedFromBackup)
        } else {
            XCTFail()
        }

        // test on entire directory
        try await sut.save(images, as: "photos/", in: .documents)
        try await sut.doNotBackup(for: "photos/", in: .documents)
        let albumUrl = try await sut.url(for: "photos/", in: .documents)
        if let resourceValues = try? albumUrl.resourceValues(forKeys: [.isExcludedFromBackupKey]),
           let isExcludedFromBackup = resourceValues.isExcludedFromBackup {
            XCTAssert(isExcludedFromBackup)
        } else {
            XCTFail()
        }

        // Do not backup (URL)
        try await sut.save(messages[0], as: "Messages/message2.json", in: .documents)
        let message2Url = try await sut.url(for: "Messages/message2.json", in: .documents)
        try await sut.doNotBackup(message2Url)
        if let resourceValues = try? message2Url.resourceValues(forKeys: [.isExcludedFromBackupKey]),
           let isExcludedFromBackup = resourceValues.isExcludedFromBackup {
            XCTAssert(isExcludedFromBackup)
        } else {
            XCTFail()
        }

        // test on entire directory
        try await sut.save(images, as: "photos2/", in: .documents)
        let album2Url = try await sut.url(for: "photos2", in: .documents)
        try await sut.doNotBackup(album2Url)
        if let resourceValues = try? album2Url.resourceValues(forKeys: [.isExcludedFromBackupKey]),
           let isExcludedFromBackup = resourceValues.isExcludedFromBackup {
            XCTAssert(isExcludedFromBackup)
        } else {
            XCTFail()
        }

        // Backup
        try await sut.backup("Messages/message.json", in: .documents)
        let newMessageUrl = try await sut.url(for: "Messages/message.json", in: .documents) // we have to create a new url to access its new resource values
        if let resourceValues = try? newMessageUrl.resourceValues(forKeys: [.isExcludedFromBackupKey]),
           let isExcludedFromBackup = resourceValues.isExcludedFromBackup {
            XCTAssertFalse(isExcludedFromBackup)
        } else {
            XCTFail()
        }

        // test on entire directory
        try await sut.backup("photos/", in: .documents)
        let newAlbumUrl = try await sut.url(for: "photos/", in: .documents)
        if let resourceValues = try? newAlbumUrl.resourceValues(forKeys: [.isExcludedFromBackupKey]),
           let isExcludedFromBackup = resourceValues.isExcludedFromBackup {
            XCTAssertFalse(isExcludedFromBackup)
        } else {
            XCTFail()
        }

        // Backup (URL)
        try await sut.backup(message2Url)
        let newMessage2Url = try await sut.url(for: "Messages/message2.json", in: .documents) // we have to create a new url to access its new resource values
        if let resourceValues = try? newMessage2Url.resourceValues(forKeys: [.isExcludedFromBackupKey]),
           let isExcludedFromBackup = resourceValues.isExcludedFromBackup {
            XCTAssertFalse(isExcludedFromBackup)
        } else {
            XCTFail()
        }

        // test on entire directory
        try await sut.backup(album2Url)
        let newAlbum2Url = try await sut.url(for: "photos2/", in: .documents)
        if let resourceValues = try? newAlbum2Url.resourceValues(forKeys: [.isExcludedFromBackupKey]),
           let isExcludedFromBackup = resourceValues.isExcludedFromBackup {
            XCTAssertFalse(isExcludedFromBackup)
        } else {
            XCTFail()
        }
    }

    func testMove() async throws {
        try await sut.save(messages[0],as: "message.json", in: .caches)
        try await sut.move("message.json", from: .caches, to: .documents)
        let exist1 = await sut.exists("message.json", in: .caches)
        let exist2 = await sut.exists("message.json", in: .documents)

        XCTAssertFalse(exist1)
        XCTAssert(exist2)

        let existingFileUrl = try await sut.url(for: "message.json", in: .documents)
        let newFileUrl = try await sut.url(for: "message.json", in: .caches)
        try await sut.move(from: existingFileUrl, to: newFileUrl)
        let exist3 = await sut.exists("message.json", in: .documents)
        let exist4 = await sut.exists("message.json", in: .caches)
        XCTAssertFalse(exist3)
        XCTAssert(exist4)

        // Array of images in folder hierarchy
        try await sut.save(images, as: "album/", in: .caches)
        try await sut.move("album/", from: .caches, to: .documents)
        let exist5 = await sut.exists("album/", in: .caches)
        let exist6 = await sut.exists("album/", in: .documents)
        XCTAssertFalse(exist5)
        XCTAssert(exist6)

        let existingFolderUrl = try await sut.url(for: "album/", in: .documents)
        let newFolderUrl = try await sut.url(for: "album/", in: .caches)
        try await sut.move(from: existingFolderUrl, to: newFolderUrl)
        let exist7 = await sut.exists("album/", in: .documents)
        let exist8 = await sut.exists("album/", in: .caches)
        XCTAssertFalse(exist7)
        XCTAssert(exist8)

    }

    func testRename() async throws {
        try await sut.clear(.caches)
        try await sut.save(messages[0], as: "oldName.json", in: .caches )
        try await sut.rename("oldName.json", from: .caches, to: "newName.json")
        let exist1 = await sut.exists("oldName.json", in: .caches)
        let exist2 = await sut.exists("newName.json", in: .caches)
        XCTAssertFalse(exist1)
        XCTAssert(exist2)

        // Array of images in folder
        try await sut.save(images,as: "oldAlbumName/", in: .caches)
        try await sut.rename("oldAlbumName/", from: .caches, to: "newAlbumName/")
        let exist3 = await sut.exists("oldAlbumName/", in: .caches)
        let exist4 = await sut.exists("newAlbumName/", in: .caches)
        XCTAssertFalse(exist3)
        XCTAssert(exist4)
    }

    func testIsFolder() async throws {
        try await sut.clear(.caches)
        try await sut.save(messages[0],as: "message.json",  in: .caches)
        let messageUrl = try await sut.url(for: "message.json", in: .caches)
        let result1 = await sut.isFolder(messageUrl)
        XCTAssertFalse(result1)

        // Array of images in folder
        try await sut.clear(.caches)
        try await sut.save(images, as: "album/", in: .caches)
        let albumUrl = try await sut.url(for: "album", in: .caches)
        let result2 = await sut.isFolder(albumUrl)
        XCTAssertTrue(result2)
    }

    //
    //    // MARK: Edge cases
    //
    func testWorkingWithFolderWithoutBackSlash() async throws  {
        try await sut.save(images, as: "album", in: .caches)
        try await sut.rename("album", from: .caches, to: "newAlbumName")
        let exist1 = await sut.exists("album", in: .caches)
        let exist2 = await sut.exists("newAlbumName", in: .caches)
        XCTAssertFalse(exist1)
        XCTAssert(exist2)

        try await sut.remove("newAlbumName", from: .caches)
        let exist3 = await sut.exists("newAlbumName", in: .caches)
        XCTAssertFalse(exist3)
    }

    func testOverwrite() async  {
        do {
            let one = messages[1]
            let two = messages[2]
            try await sut.save(one, as: "message.json", in: .caches)
            try await sut.save(two, as: "message.json", in: .caches)
            // Array of images in folder
            let albumOne = [images[0], images[1]]
            let albumTwo = [images[1], images[2]]
            try await sut.save(albumOne, as: "album/", in: .caches )
            try await sut.save(albumTwo, as: "album/", in: .caches)
        } catch let error as NSError {
            // We want an NSCocoa error to be thrown when we try writing to the same file location again without first removing it first
            let alreadyExistsErrorCode = 516
            XCTAssert(error.code == alreadyExistsErrorCode)
        }
    }

    func testInvalidName() async throws {
        try await sut.save(messages,  as: "//////messages.json", in: .documents)
        let exist = await sut.exists("messages.json", in: .documents)
        XCTAssert(exist)
    }

    func testAddDifferentFileTypes() async throws {
        try await sut.save(messages, as: "Folder/messages.json", in: .documents )
        let exist1 = await sut.exists("Folder/messages.json", in: .documents)
        XCTAssert(exist1)
        try await sut.save(images[0], as: "Folder/image1.png", in: .documents)
        let exist2 = await sut.exists("Folder/image1.png", in: .documents)
        XCTAssert(exist2)
        try await sut.save(images[1], as: "Folder/image2.jpg", in: .documents )
        let exist3 = await sut.exists("Folder/image2.jpg", in: .documents)
        XCTAssert(exist3)
        try await sut.save(images[2], as: "Folder/image3.jpeg", in: .documents)
        let exist4 = await sut.exists("Folder/image3.jpeg", in: .documents)
        XCTAssert(exist4)

        let files: [Data] = try await sut.fetch(from: "Folder", in: .documents)
        XCTAssert(files.count == 4)

        let album: [UIImage] = try await sut.fetch(from: "Folder", in: .documents)
        XCTAssert(album.count == 3)

    }

    // Test sorting of many files saved to folder as array
    func testFilesRetrievalSorting() async throws {
        let manyObjects = data + data + data + data + data
        try await sut.save(manyObjects, as: "Folder/", in: .documents)

        let retrievedFiles: [Data] = try await sut.fetch(from: "Folder", in: .documents)

        for i in 0..<manyObjects.count {
            let object = manyObjects[i]
            let file = retrievedFiles[i]
            XCTAssert(object == file)
        }
    }

    // Test saving struct/structs as a folder
    func testExpectedErrorForSavingStructsAsFilesInAFolder() async {
        do {
            let oneMessage = messages[0]
            let multipleMessages = messages

            try await sut.save(oneMessage, as: "Folder/", in: .documents)
            try await sut.save(multipleMessages, as: "Folder/", in: .documents)
            try await sut.append(oneMessage, to: "Folder/", in: .documents)
            let _ :[Message] = try await sut.fetch(from: "Folder/", in: .documents)
        } catch let error as NSError {
            XCTAssert(error.code == SPSDomainError.invalidFileName.rawValue)
        }
    }

        // Test iOS 11 Volume storage resource values
        func testVolumeStorageResourceValues() {
            XCTAssert(sut.totalCapacity != nil && sut.totalCapacity != 0)
            XCTAssert(sut.availableCapacity != nil && sut.availableCapacity != 0)
            XCTAssert(sut.availableCapacityForImportantUsage != nil && sut.availableCapacityForImportantUsage != 0)
            XCTAssert(sut.availableCapacityForOpportunisticUsage != nil && sut.availableCapacityForOpportunisticUsage != 0)

            print("\n\n============== Disk Volume Information ==============")
            print("Disk.totalCapacity = \(sut.totalCapacity!)")
            print("Disk.availableCapacity = \(sut.availableCapacity!)")
            print("Disk.availableCapacityForImportantUsage = \(sut.availableCapacityForImportantUsage!)")
            print("Disk.availableCapacityForOpportunisticUsage = \(sut.availableCapacityForOpportunisticUsage!)")
            print("============================================================\n\n")
        }

        // Test Equitability for Directory enum
        func testDirectoryEquitability() {
            let directories: [DirectoryEndpoint] = [.documents, .caches, .applicationSupport, .temporary]
            for directory in directories {
                XCTAssert(directory == directory)
            }
            for directory in directories {
                let otherDirectories = directories.filter { $0 != directory }
                otherDirectories.forEach {
                    XCTAssert($0 != directory)
                }
            }

            let sameAppGroupName = "SameName"
            let sharedDirectory1 = DirectoryEndpoint.sharedContainer(appGroupName: sameAppGroupName)
            let sharedDirectory2 = DirectoryEndpoint.sharedContainer(appGroupName: sameAppGroupName)
            XCTAssert(sharedDirectory1 == sharedDirectory2)

            let sharedDirectory3 = DirectoryEndpoint.sharedContainer(appGroupName: "Another Name")
            let sharedDirectory4 = DirectoryEndpoint.sharedContainer(appGroupName: "Different Name")
            XCTAssert(sharedDirectory3 != sharedDirectory4)
        }

        // Test custom JSONEncoder and JSONDecoder
        func testCustomEncoderDecoder() async {
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let sut2 = SimplySaveClient(decoder:decoder, encoder: encoder)
            do {
                // 1 struct
                try await sut2.save(messages[0], as: "message.json", in: .documents)
                let messageUrl = try await sut.url(for: "message.json", in: .documents)
                print("A message was saved as \(messageUrl.absoluteString)")

                let retrievedMessage: Message = try await sut.fetch(from: "message.json", in: .documents)
                XCTAssert(messages[0] == retrievedMessage)

                // Array of structs
                try  await sut.save(messages, as: "messages.json", in: .documents)
                let messagesUrl = try  await sut.url(for: "messages.json", in: .documents)
                print("Messages were saved as \(messagesUrl.absoluteString)")
                let retrievedMessages:[Message] = try  await sut.fetch(from: "messages.json", in: .documents)
                XCTAssert(messages == retrievedMessages)

                // Append
                try  await sut.append(messages[0], to: "messages.json", in: .documents)
                let retrievedUpdatedMessages: [Message] = try await sut.fetch(from: "messages.json", in: .documents)
                XCTAssert((messages + [messages[0]]) == retrievedUpdatedMessages)
            } catch {
                fatalError(convertErrorToString(error))
            }
        }
}

// UIImage's current Equatable implementation is buggy, this is a simply workaround to compare images' Data
extension UIImage {
    func dataEquals(_ otherImage: UIImage) -> Bool {
        if let selfData = self.pngData(), let otherData = otherImage.pngData() {
            return selfData == otherData
        } else {
            print("Could not convert images to PNG")
            return false
        }
    }
}
