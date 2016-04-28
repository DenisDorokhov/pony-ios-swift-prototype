//
// Created by Denis Dorokhov on 28/04/16.
// Copyright (c) 2016 Denis Dorokhov. All rights reserved.
//

import Foundation
import XCGLogger

protocol RestUrlDao: class {
    func fetchUrl() -> NSURL?
    func storeUrl(url: NSURL)
    func removeUrl()
}

class RestUrlDaoImpl: RestUrlDao {

    let KEY_URL = "RestUrlDaoImpl.url"

    let log = XCGLogger.defaultInstance()

    func fetchUrl() -> NSURL? {

        let url = NSUserDefaults.standardUserDefaults().stringForKey(KEY_URL)

        return url != nil ? NSURL(string: url!) : nil
    }

    func storeUrl(url: NSURL) {

        NSUserDefaults.standardUserDefaults().setObject(url.absoluteString, forKey: KEY_URL)
        NSUserDefaults.standardUserDefaults().synchronize()

        log.debug("URL stored: \(url).")
    }

    func removeUrl() {

        NSUserDefaults.standardUserDefaults().removeObjectForKey(KEY_URL)
        NSUserDefaults.standardUserDefaults().synchronize()

        log.debug("URL removed.")
    }
}
