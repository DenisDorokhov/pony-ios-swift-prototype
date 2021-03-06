//
// Created by Denis Dorokhov on 30/04/16.
// Copyright (c) 2016 Denis Dorokhov. All rights reserved.
//

import Foundation
import Quick
import Nimble
import ReachabilitySwift

@testable import Pony

class RestServiceSpec: QuickSpec {

    private let DEMO_URL = "http://pony.dorokhov.net/demo"
    private let DEMO_EMAIL = "foo@bar.com"
    private let DEMO_PASSWORD = "demo"

    override func spec() {

        Nimble.AsyncDefaults.Timeout = 5

        describe("RestServiceImpl") {

            var service: RestServiceImpl!
            beforeEach {
                TestUtils.cleanAll()
                service = RestServiceImpl()
                service.alamofireManager = AlamofireManager(debug: true)
                service.tokenPairDao = TokenPairDaoMock()
                service.restUrlDao = RestUrlDaoMock(url: self.DEMO_URL)
            }
            afterEach {
                TestUtils.cleanAll()
            }

            let credentials = Credentials(email: self.DEMO_EMAIL, password: self.DEMO_PASSWORD)

            let authenticate: Credentials -> Authentication? = {
                credentials in
                var authentication: Authentication?
                waitUntil(timeout: Nimble.AsyncDefaults.Timeout) {
                    done in
                    service.authenticate(credentials, onSuccess: {
                        authentication = $0
                        service.tokenPairDao.storeTokenPair(TokenPair(authentication: $0))
                        done()
                    })
                }
                return authentication
            }
            let getArtists: Void -> [Artist]? = {
                var artists: [Artist]?
                waitUntil(timeout: Nimble.AsyncDefaults.Timeout) {
                    done in
                    service.getArtists(onSuccess: {
                        artists = $0
                        done()
                    })
                }
                return artists
            }
            let getArtistAlbums: Int64 -> ArtistAlbums? = {
                artistId in
                var artistAlbums: ArtistAlbums?
                waitUntil(timeout: Nimble.AsyncDefaults.Timeout) {
                    done in
                    service.getArtistAlbums(artistId, onSuccess: {
                        artistAlbums = $0
                        done()
                    })
                }
                return artistAlbums
            }

            let isOffline = try! Reachability.reachabilityForLocalWiFi().currentReachabilityStatus == .NotReachable
            it("should run online") {
                expect(isOffline).to(beFalse())
            }
            if isOffline {
                return
            }

            it("should handle errors") {
                service.restUrlDao = RestUrlDaoMock(url: "http://notExistingDomain")
                var errors: [Error]?
                service.getInstallation(onFailure: {
                    errors = $0
                })
                expect(errors).toEventuallyNot(beNil())
            }

            it("should get installation") {
                var installation: Installation?
                service.getInstallation(onSuccess: {
                    installation = $0
                })
                expect(installation).toEventuallyNot(beNil())
            }

            it("should authenticate") {
                authenticate(credentials)
            }

            it("should logout") {
                authenticate(credentials)
                var user: User?
                service.logout(onSuccess: {
                    user = $0
                })
                expect(user).toEventuallyNot(beNil())
            }

            it("should get current user") {
                authenticate(credentials)
                var user: User?
                service.getCurrentUser(onSuccess: {
                    user = $0
                })
                expect(user).toEventuallyNot(beNil())
            }

            it("should refresh token") {
                authenticate(credentials)
                var authentication: Authentication?
                service.refreshToken(onSuccess: {
                    authentication = $0
                })
                expect(authentication).toEventuallyNot(beNil())
            }

            it("should get artists") {
                authenticate(credentials)
                expect(getArtists()).toNot(beNil())
            }

            it("should get artist albums") {
                authenticate(credentials)
                if let artists = getArtists() {
                    expect(getArtistAlbums(artists[0].id)).toNot(beNil())
                } else {
                    fail()
                }
            }

            it("should download image") {
                authenticate(credentials)
                if let artists = getArtists() {
                    var image: UIImage?
                    service.downloadImage(artists[0].artworkUrl!, onSuccess: {
                        image = $0
                    })
                    expect(image).toEventuallyNot(beNil())
                } else {
                    fail()
                }
            }

            it("should download song") {
                authenticate(credentials)
                if let artists = getArtists() {
                    if let artistAlbums = getArtistAlbums(artists[0].id) {
                        let filePath = FileUtils.generateTemporaryPath()
                        var progressCalled = false
                        var completed = false
                        service.downloadSong(artistAlbums.albums[0].songs[0].url, toFile: filePath, onProgress: {
                            progress in
                            progressCalled = true
                        }, onSuccess: {
                            completed = true
                        })
                        expect(completed).toEventually(beTrue(), timeout: 10)
                        expect(progressCalled).to(beTrue())
                        expect(NSFileManager.defaultManager().fileExistsAtPath(filePath)).to(beTrue())
                    } else {
                        fail()
                    }
                } else {
                    fail()
                }
            }
        }
    }
}
