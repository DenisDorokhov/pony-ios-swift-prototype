//
// Created by Denis Dorokhov on 28/04/16.
// Copyright (c) 2016 Denis Dorokhov. All rights reserved.
//

import Foundation

class FileUtils {

    static var documentsPath: String = {
        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
        return try! FileUtils.createDirectory(paths[0])
    }()

    static var cachePath: String = {
        let paths = NSSearchPathForDirectoriesInDomains(.CachesDirectory, .UserDomainMask, true)
        return try! FileUtils.createDirectory(paths[0])
    }()

    static var temporaryPath: String = {
        return try! FileUtils.createDirectory(FileUtils.generateRandomPathInDirectory(NSTemporaryDirectory()))
    }()

    static func generateTemporaryPath() -> String {
        return FileUtils.generateRandomPathInDirectory(temporaryPath)
    }

    static func createTemporaryDirectory() throws -> String {
        let path = generateTemporaryPath()
        try NSFileManager.defaultManager().createDirectoryAtPath(path, withIntermediateDirectories: true, attributes: nil)
        return path
    }

    static func createTemporaryFile() throws -> String {
        let path = generateTemporaryPath()
        NSFileManager.defaultManager().createFileAtPath(path, contents: nil, attributes: nil)
        return path
    }

    static func pathInDocuments(filePath: String) -> String {
        return (documentsPath as NSString).stringByAppendingPathComponent(filePath)
    }

    static func pathInCache(filePath: String) -> String {
        return (cachePath as NSString).stringByAppendingPathComponent(filePath)
    }

    static func createDirectory(directoryPath: String) throws -> String {
        if !NSFileManager.defaultManager().fileExistsAtPath(directoryPath) {
            try NSFileManager.defaultManager().createDirectoryAtPath(directoryPath, withIntermediateDirectories: true, attributes: nil)
        }
        return directoryPath
    }

    static func generateRandomPathInDirectory(directoryPath: String) -> String {
        var result: String
        repeat {
            result = (directoryPath as NSString).stringByAppendingPathComponent(RandomUtils.uuid())
        } while NSFileManager.defaultManager().fileExistsAtPath(result)
        return result
    }
}
