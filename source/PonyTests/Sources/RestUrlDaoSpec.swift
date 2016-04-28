//
// Created by Denis Dorokhov on 28/04/16.
// Copyright (c) 2016 Denis Dorokhov. All rights reserved.
//

import Foundation
import Quick
import Nimble

@testable import Pony

class RestUrlDaoSpec: QuickSpec {
    override func spec() {
        describe("RestUrlDao") {

            var dao: RestUrlDaoImpl!
            beforeEach {
                TestUtils.cleanAll()
                dao = RestUrlDaoImpl()
            }
            afterEach {
                TestUtils.cleanAll()
            }

            it("should be empty after cleaning") {
                expect(dao.fetchUrl()).to(beNil())
            }

            it("should store and fetch URL") {

                dao.storeUrl(NSURL(string: "http://google.com")!)

                let url = dao.fetchUrl()

                expect(url).toNot(beNil())
                expect(url!.absoluteString).to(equal("http://google.com"))
            }

            it("should remove token pair") {
                dao.storeUrl(NSURL(string: "http://google.com")!)
                dao.removeUrl()
                expect(dao.fetchUrl()).to(beNil())
            }
        }
    }
}
