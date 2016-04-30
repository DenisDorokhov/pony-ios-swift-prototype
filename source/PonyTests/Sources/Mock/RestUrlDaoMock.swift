//
// Created by Denis Dorokhov on 30/04/16.
// Copyright (c) 2016 Denis Dorokhov. All rights reserved.
//

import Foundation

@testable import Pony

class RestUrlDaoMock: RestUrlDao {

    var url: NSURL?

    init(url: String? = nil) {
        self.url = url != nil ? NSURL(string: url!)! : nil
    }

    func fetchUrl() -> NSURL? {
        return url
    }

    func storeUrl(url: NSURL) {
        self.url = url
    }

    func removeUrl() {
        url = nil
    }
}
