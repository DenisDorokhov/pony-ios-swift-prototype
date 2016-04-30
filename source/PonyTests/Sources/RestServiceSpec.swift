//
// Created by Denis Dorokhov on 30/04/16.
// Copyright (c) 2016 Denis Dorokhov. All rights reserved.
//

import Foundation
import Quick
import Nimble

@testable import Pony

class RestServiceSpec: QuickSpec {

    private let DEMO_URL = "http://pony.dorokhov.net/demo"
    private let DEMO_EMAIL = "foo@bar.com"
    private let DEMO_PASSWORD = "demo"

    override func spec() {

        Nimble.AsyncDefaults.Timeout = 3

        describe("RestService") {

            var service: RestService!
            beforeEach {
                TestUtils.cleanAll()
                service = RestService()
                service.alamofireManager = AlamofireManager(debug: true)
                service.tokenPairDao = TokenPairDaoMock()
                service.restUrlDao = RestUrlDaoMock(url: self.DEMO_URL)
            }
            afterEach {
                TestUtils.cleanAll()
            }

            let credentials = CredentialsDto(email: self.DEMO_EMAIL, password: self.DEMO_PASSWORD)
            let authenticate: (CredentialsDto -> AuthenticationDto?) = {
                credentials in
                var authentication: AuthenticationDto? = nil
                waitUntil {
                    done in
                    service.authenticate(credentials, onSuccess: {
                        authentication = $0
                        service.tokenPairDao.storeTokenPair(TokenPair(authentication: $0))
                        done()
                    }, onFailure: {
                        errors in
                        done()
                    })
                }
                return authentication
            }

            it("should handle errors") {
                service.restUrlDao = RestUrlDaoMock(url: "http://notExistingDomain")
                var errors: [ErrorDto]?
                service.getInstallation(onFailure: {
                    errors = $0
                })
                expect(errors).toEventuallyNot(beNil())
            }

            it("should get installation") {
                var installation: InstallationDto?
                service.getInstallation(onSuccess: {
                    installation = $0
                })
                expect(installation).toEventuallyNot(beNil())
            }

            it("should authenticate") {
                let authentication = authenticate(credentials)
                expect(authentication).notTo(beNil())
            }

            it("should logout") {
                authenticate(credentials)
                var user: UserDto?
                service.logout(onSuccess: {
                    user = $0
                })
                expect(user).toEventuallyNot(beNil())
            }

            it("should get current user") {
                authenticate(credentials)
                var user: UserDto?
                service.getCurrentUser(onSuccess: {
                    user = $0
                })
                expect(user).toEventuallyNot(beNil())
            }

            it("should refresh token") {
                authenticate(credentials)
                var authentication: AuthenticationDto?
                service.refreshToken(onSuccess: {
                    authentication = $0
                })
                expect(authentication).toEventuallyNot(beNil())
            }
        }
    }
}
