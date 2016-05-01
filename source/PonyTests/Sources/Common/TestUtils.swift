//
// Created by Denis Dorokhov on 28/04/16.
// Copyright (c) 2016 Denis Dorokhov. All rights reserved.
//

import Foundation
import KeychainSwift

@testable import Pony

class TestUtils {

    static func cleanAll() {
        cleanFiles()
        cleanUserDefaults()
        cleanKeychain()
    }

    static func cleanFiles() {

        let fileManager = NSFileManager.defaultManager()

        for item in try! fileManager.contentsOfDirectoryAtPath(FileUtils.documentsPath) {
            try! fileManager.removeItemAtPath(NSString(string: FileUtils.documentsPath).stringByAppendingPathComponent(item))
        }
        for item in try! fileManager.contentsOfDirectoryAtPath(FileUtils.cachePath) {
            try! fileManager.removeItemAtPath(NSString(string: FileUtils.cachePath).stringByAppendingPathComponent(item))
        }
        for item in try! fileManager.contentsOfDirectoryAtPath(FileUtils.temporaryPath) {
            try! fileManager.removeItemAtPath(NSString(string: FileUtils.temporaryPath).stringByAppendingPathComponent(item))
        }
    }

    static func cleanUserDefaults() {
        NSUserDefaults.standardUserDefaults().removePersistentDomainForName(NSBundle.mainBundle().bundleIdentifier!)
        NSUserDefaults.standardUserDefaults().synchronize()
    }

    static func cleanKeychain() {
        KeychainSwift().clear()
    }
}
