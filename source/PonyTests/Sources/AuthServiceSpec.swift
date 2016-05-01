//
// Created by Denis Dorokhov on 01/05/16.
// Copyright (c) 2016 Denis Dorokhov. All rights reserved.
//

import Foundation
import Quick
import Nimble
import SwiftDate

@testable import Pony

class AuthServiceDelegateMock: AuthServiceDelegate {

    var didAuthenticateUser: UserDto?
    var didUpdateUser: UserDto?
    var didLogoutUser: UserDto?

    func authService(authService: AuthService, didAuthenticateUser user: UserDto) {
        didAuthenticateUser = user
    }

    func authService(authService: AuthService, didUpdateUser user: UserDto) {
        didUpdateUser = user
    }

    func authService(authService: AuthService, didLogoutUser user: UserDto) {
        didLogoutUser = user
    }
}

func buildCredentialsMock() -> CredentialsDto {
    return CredentialsDto(email: "foo@bar.com", password: "demo")
}
func buildUserMock() -> UserDto {
    return UserDto(id: 1, creationDate: NSDate(), name: "Foobar", email: "foo@bar.com", role: .User)
}
func buildAuthenticationMock(accessTokenExpiration accessTokenExpiration: NSDate = 1.days.ago, refreshTokenExpiration: NSDate = 1.days.ago) -> AuthenticationDto {
    return AuthenticationDto(accessToken: "someAccessToken", accessTokenExpiration: accessTokenExpiration,
            refreshToken: "someRefreshToken", refreshTokenExpiration: refreshTokenExpiration,
            user: buildUserMock())
}

class AuthServiceSpec: QuickSpec {
    override func spec() {
        describe("AuthService") {

            var restServiceMock: RestServiceMock!
            var tokenPairDaoMock: TokenPairDaoMock!
            var delegateMock: AuthServiceDelegateMock!
            var authService: AuthService!
            beforeEach {

                TestUtils.cleanAll()

                restServiceMock = RestServiceMock()
                restServiceMock.authentication = buildAuthenticationMock()
                restServiceMock.currentUser = buildUserMock()
                restServiceMock.logoutUser = buildUserMock()
                restServiceMock.refreshTokenAuthentication = buildAuthenticationMock(refreshTokenExpiration: 1.days.fromNow)

                tokenPairDaoMock = TokenPairDaoMock()

                delegateMock = AuthServiceDelegateMock()

                authService = AuthService()
                authService.tokenPairDao = tokenPairDaoMock
                authService.restService = restServiceMock
                authService.addDelegate(delegateMock)
            }
            afterEach {
                TestUtils.cleanAll()
            }

            let authenticate: Void -> UserDto = {
                var user: UserDto!
                waitUntil {
                    done in
                    authService.authenticate(buildCredentialsMock(), onSuccess: {
                        user = $0
                        done()
                    })
                }
                return user
            }
            let updateUser: Void -> UserDto = {
                var user: UserDto!
                waitUntil {
                    done in
                    authService.updateUser(onSuccess: {
                        user = $0
                        done()
                    })
                }
                return user
            }

            it("should authenticate") {
                expect(authenticate()).toNot(beNil())
                expect(delegateMock.didAuthenticateUser).toNot(beNil())
                expect(authService.isAuthenticated).to(beTrue())
                expect(authService.currentUser).toNot(beNil())
            }

            it("should logout before authenticating again") {
                authenticate()
                delegateMock.didAuthenticateUser = nil
                authenticate()
                expect(delegateMock.didAuthenticateUser).toNot(beNil())
                expect(delegateMock.didLogoutUser).toNot(beNil())
            }

            it("should update user after authentication") {
                authenticate()
                expect(updateUser()).toNot(beNil())
                expect(delegateMock.didUpdateUser).toNot(beNil())
            }

            it("should update user with existing token") {
                tokenPairDaoMock.storeTokenPair(TokenPair(authentication: buildAuthenticationMock()))
                expect(updateUser()).toNot(beNil())
                expect(delegateMock.didUpdateUser).toNot(beNil())
            }

            it("should logout") {
                authenticate()
                var user: UserDto?
                authService.logout(onSuccess: {
                    user = $0
                })
                expect(user).toEventuallyNot(beNil())
                expect(delegateMock.didLogoutUser).toNot(beNil())
                expect(authService.currentUser).to(beNil())
                expect(authService.isAuthenticated).to(beFalse())
            }

            it("should refresh token when checking access token expiration") {
                authenticate()
                expect(tokenPairDaoMock.fetchTokenPair()?.refreshTokenExpiration < NSDate()).to(beTrue())
                waitUntil {
                    done in
                    authService.checkAccessTokenExpiration {
                        done()
                    }
                }
                expect(tokenPairDaoMock.fetchTokenPair()?.refreshTokenExpiration > NSDate()).to(beTrue())
            }

            it("should logout after access denied error when refreshing token") {
                authenticate()
                restServiceMock.refreshTokenAuthentication = nil
                restServiceMock.errors = [ErrorDto.accessDenied]
                waitUntil {
                    done in
                    authService.checkAccessTokenExpiration {
                        done()
                    }
                }
                expect(delegateMock.didLogoutUser).toNot(beNil())
                expect(authService.isAuthenticated).to(beFalse())
            }
        }
    }
}
