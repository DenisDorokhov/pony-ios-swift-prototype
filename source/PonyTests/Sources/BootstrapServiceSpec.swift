//
// Created by Denis Dorokhov on 01/05/16.
// Copyright (c) 2016 Denis Dorokhov. All rights reserved.
//

import Foundation
import Quick
import Nimble

@testable import Pony

private class BootstrapServiceDelegateMock: BootstrapServiceDelegate {

    var didStartBootstrap: Bool = false
    var didFinishBootstrap: Bool = false
    var didStartBackgroundActivity: Bool = false
    var didRequireRestUrl: Bool = false
    var didRequireAuthentication: Bool = false
    var didFailWithErrors: [ErrorDto]?

    func bootstrapServiceDidStartBootstrap(bootstrapService: BootstrapService) {
        didStartBootstrap = true
    }

    func bootstrapServiceDidFinishBootstrap(bootstrapService: BootstrapService) {
        didFinishBootstrap = true
    }

    func bootstrapServiceDidStartBackgroundActivity(bootstrapService: BootstrapService) {
        didStartBackgroundActivity = true
    }

    func bootstrapServiceDidRequireRestUrl(bootstrapService: BootstrapService) {
        didRequireRestUrl = true
    }

    func bootstrapServiceDidRequireAuthentication(bootstrapService: BootstrapService) {
        didRequireAuthentication = true
    }

    func bootstrapService(bootstrapService: BootstrapService, didFailWithErrors errors: [ErrorDto]) {
        didFailWithErrors = errors
    }
}

private func buildUserMock() -> UserDto {
    return UserDto(id: 1, creationDate: NSDate(), name: "Foobar", email: "foo@bar.com", role: .User)
}

private func buildAuthenticationMock() -> AuthenticationDto {
    return AuthenticationDto(accessToken: "someAccessToken", accessTokenExpiration: NSDate(),
            refreshToken: "someRefreshToken", refreshTokenExpiration: NSDate(),
            user: buildUserMock())
}

class BootstrapServiceSpec: QuickSpec {
    override func spec() {

        describe("BootstrapService") {

            var restUrlDaoMock: RestUrlDaoMock!
            var tokenPairDaoMock: TokenPairDaoMock!
            var restServiceMock: RestServiceMock!
            var authService: AuthService!
            var delegateMock: BootstrapServiceDelegateMock!
            var bootstrapService: BootstrapService!
            beforeEach {
                TestUtils.cleanAll()

                restServiceMock = RestServiceMock()
                restServiceMock.logoutUser = buildUserMock()
                restServiceMock.currentUser = buildUserMock()

                tokenPairDaoMock = TokenPairDaoMock()

                authService = AuthService()
                authService.tokenPairDao = tokenPairDaoMock
                authService.restService = restServiceMock

                delegateMock = BootstrapServiceDelegateMock()

                restUrlDaoMock = RestUrlDaoMock()

                bootstrapService = BootstrapService()
                bootstrapService.restUrlDao = restUrlDaoMock
                bootstrapService.authService = authService
                bootstrapService.addDelegate(delegateMock)
            }
            afterEach {
                TestUtils.cleanAll()
            }

            it("should start bootstrap and require rest url") {
                bootstrapService.bootstrap()
                expect(delegateMock.didStartBootstrap).to(beTrue())
                expect(delegateMock.didRequireRestUrl).to(beTrue())
            }

            it("should start background activity and require authentication") {
                restUrlDaoMock.storeUrl(NSURL(string: "http://someUrl")!)
                bootstrapService.bootstrap()
                expect(delegateMock.didRequireAuthentication).toEventually(beTrue())
                expect(delegateMock.didStartBackgroundActivity).to(beTrue())
            }

            it("should finish bootstrap") {
                restUrlDaoMock.storeUrl(NSURL(string: "http://someUrl")!)
                tokenPairDaoMock.storeTokenPair(TokenPair(authentication: buildAuthenticationMock()))
                bootstrapService.bootstrap()
                expect(delegateMock.didFinishBootstrap).toEventually(beTrue())
            }

            it("should fail on error") {
                restUrlDaoMock.storeUrl(NSURL(string: "http://someUrl")!)
                tokenPairDaoMock.storeTokenPair(TokenPair(authentication: buildAuthenticationMock()))
                restServiceMock.currentUser = nil
                bootstrapService.bootstrap()
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
                bootstrapService.clearBootstrapData()
                expect(authService.isAuthenticated).to(beFalse())
                expect(restUrlDaoMock.fetchUrl()).to(beNil())
            }
        }
    }
}
