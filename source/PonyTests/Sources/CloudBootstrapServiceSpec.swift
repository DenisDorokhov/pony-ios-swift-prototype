//
// Created by Denis Dorokhov on 01/05/16.
// Copyright (c) 2016 Denis Dorokhov. All rights reserved.
//

import Foundation
import Quick
import Nimble

@testable import Pony

private class CloudBootstrapServiceDelegateMock: CloudBootstrapServiceDelegate {

    var didStartBootstrap: Bool = false
    var didFinishBootstrap: Bool = false
    var didStartBackgroundActivity: Bool = false
    var didRequireRestUrl: Bool = false
    var didRequireAuthentication: Bool = false
    var didFailWithErrors: [Error]?

    func cloudBootstrapServiceDidStartBootstrap(cloudBootstrapService: CloudBootstrapService) {
        didStartBootstrap = true
    }

    func cloudBootstrapServiceDidFinishBootstrap(cloudBootstrapService: CloudBootstrapService) {
        didFinishBootstrap = true
    }

    func cloudBootstrapServiceDidStartBackgroundActivity(cloudBootstrapService: CloudBootstrapService) {
        didStartBackgroundActivity = true
    }

    func cloudBootstrapServiceDidRequireRestUrl(cloudBootstrapService: CloudBootstrapService) {
        didRequireRestUrl = true
    }

    func cloudBootstrapServiceDidRequireAuthentication(cloudBootstrapService: CloudBootstrapService) {
        didRequireAuthentication = true
    }

    func cloudBootstrapService(cloudBootstrapService: CloudBootstrapService, didFailWithErrors errors: [Error]) {
        didFailWithErrors = errors
    }
}

private func buildUserMock() -> User {
    return User(id: 1, creationDate: NSDate(), name: "Foobar", email: "foo@bar.com", role: .User)
}

private func buildAuthenticationMock() -> Authentication {
    return Authentication(accessToken: "someAccessToken", accessTokenExpiration: NSDate(),
            refreshToken: "someRefreshToken", refreshTokenExpiration: NSDate(),
            user: buildUserMock())
}

class CloudBootstrapServiceSpec: QuickSpec {
    override func spec() {

        describe("CloudBootstrapService") {

            var restUrlDaoMock: RestUrlDaoMock!
            var tokenPairDaoMock: TokenPairDaoMock!
            var restServiceMock: RestServiceMock!
            var authService: AuthService!
            var delegateMock: CloudBootstrapServiceDelegateMock!
            var cloudBootstrapService: CloudBootstrapService!
            beforeEach {
                TestUtils.cleanAll()

                restServiceMock = RestServiceMock()
                restServiceMock.logoutUser = buildUserMock()
                restServiceMock.currentUser = buildUserMock()

                tokenPairDaoMock = TokenPairDaoMock()

                authService = AuthService()
                authService.tokenPairDao = tokenPairDaoMock
                authService.restService = restServiceMock

                delegateMock = CloudBootstrapServiceDelegateMock()

                restUrlDaoMock = RestUrlDaoMock()

                cloudBootstrapService = CloudBootstrapService()
                cloudBootstrapService.restUrlDao = restUrlDaoMock
                cloudBootstrapService.authService = authService
                cloudBootstrapService.addDelegate(delegateMock)
            }
            afterEach {
                TestUtils.cleanAll()
            }

            it("should start bootstrap and require rest url") {
                cloudBootstrapService.bootstrap()
                expect(delegateMock.didStartBootstrap).to(beTrue())
                expect(delegateMock.didRequireRestUrl).to(beTrue())
            }

            it("should start background activity and require authentication") {
                restUrlDaoMock.storeUrl(NSURL(string: "http://someUrl")!)
                cloudBootstrapService.bootstrap()
                expect(delegateMock.didRequireAuthentication).toEventually(beTrue())
                expect(delegateMock.didStartBackgroundActivity).to(beTrue())
            }

            it("should finish bootstrap") {
                restUrlDaoMock.storeUrl(NSURL(string: "http://someUrl")!)
                tokenPairDaoMock.storeTokenPair(TokenPair(authentication: buildAuthenticationMock()))
                cloudBootstrapService.bootstrap()
                expect(delegateMock.didFinishBootstrap).toEventually(beTrue())
            }

            it("should fail on error") {
                restUrlDaoMock.storeUrl(NSURL(string: "http://someUrl")!)
                tokenPairDaoMock.storeTokenPair(TokenPair(authentication: buildAuthenticationMock()))
                restServiceMock.currentUser = nil
                cloudBootstrapService.bootstrap()
                expect(delegateMock.didFailWithErrors).toEventuallyNot(beNil())
            }

            it("should clear bootstrap data") {
                restUrlDaoMock.storeUrl(NSURL(string: "http://someUrl")!)
                tokenPairDaoMock.storeTokenPair(TokenPair(authentication: buildAuthenticationMock()))
                waitUntil {
                    done in
                    authService.updateUser(onSuccess: {
                        user in
                        done()
                    })
                }
                expect(authService.isAuthenticated).toEventually(beTrue())
                cloudBootstrapService.clearBootstrapData()
                expect(authService.isAuthenticated).to(beFalse())
                expect(restUrlDaoMock.fetchUrl()).to(beNil())
            }
        }
    }
}
