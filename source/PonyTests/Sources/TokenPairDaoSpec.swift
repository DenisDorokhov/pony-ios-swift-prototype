//
// Created by Denis Dorokhov on 28/04/16.
// Copyright (c) 2016 Denis Dorokhov. All rights reserved.
//

import Foundation
import Quick
import Nimble

@testable import Pony

class TokenPairDaoSpec: QuickSpec {
    override func spec() {

        describe("TokenPairDaoImpl") {

            var dao: TokenPairDaoImpl!
            beforeEach {
                TestUtils.cleanAll()
                dao = TokenPairDaoImpl()
            }
            afterEach {
                TestUtils.cleanAll()
            }

            it("should be empty after cleaning") {
                expect(dao.fetchTokenPair()).to(beNil())
            }

            it("should store and fetch token pair") {
                dao.storeTokenPair(self.buildTokenPair())
                expect(dao.fetchTokenPair()).notTo(beNil())
            }

            it("should remove token pair") {
                dao.storeTokenPair(self.buildTokenPair())
                dao.removeTokenPair()
                expect(dao.fetchTokenPair()).to(beNil())
            }

            it("should not fetch token after the app is uninstalled") {
                dao.storeTokenPair(self.buildTokenPair())
                TestUtils.cleanUserDefaults()
                expect(dao.fetchTokenPair()).to(beNil())
            }
        }

        describe("TokenPairDaoCached") {

            var mock: TokenPairDaoMock!
            var dao: TokenPairDaoCached!
            beforeEach {
                TestUtils.cleanAll()
                mock = TokenPairDaoMock()
                dao = TokenPairDaoCached(tokenPairDao: mock)
            }

            it("should cache token pair") {
                dao.storeTokenPair(self.buildTokenPair())
                expect(dao.fetchTokenPair()).toNot(beNil())
                expect(mock.fetchTokenPairCallsCount).to(equal(0))
            }

            it("should cache absense of token pair") {
                expect(dao.fetchTokenPair()).to(beNil())
                expect(dao.fetchTokenPair()).to(beNil())
                expect(mock.fetchTokenPairCallsCount).to(equal(1))
            }

            it("should remember absense of token pair after removal") {
                dao.storeTokenPair(self.buildTokenPair())
                dao.removeTokenPair()
                expect(dao.fetchTokenPair()).to(beNil())
                expect(mock.fetchTokenPairCallsCount).to(equal(0))
            }
        }
    }

    private func buildTokenPair() -> TokenPair {
        return TokenPair(accessToken: "someAccessToken", accessTokenExpiration: NSDate(),
                refreshToken: "someRefreshToken", refreshTokenExpiration: NSDate())
    }
}
