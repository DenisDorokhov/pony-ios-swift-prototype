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

            let authenticate: (CredentialsDto -> AuthenticationDto) = {
                credentials in
                var authentication: AuthenticationDto!
                waitUntil {
                    done in
                    service.authenticate(credentials, onSuccess: {
                        authentication = $0
                        service.tokenPairDao.storeTokenPair(TokenPair(authentication: $0))
                        done()
                    })
                }
                return authentication
            }
            let getArtists: (Void -> [ArtistDto]) = {
                var artists: [ArtistDto]!
                waitUntil {
                    done in
                    service.getArtists(onSuccess: {
                        artists = $0
                        done()
                    })
                }
                return artists
            }
            let getArtistAlbums: (Int64 -> ArtistAlbumsDto) = {
                artistId in
                var artistAlbums: ArtistAlbumsDto!
                waitUntil {
                    done in
                    service.getArtistAlbums(artistId, onSuccess: {
                        artistAlbums = $0
                        done()
                    })
                }
                return artistAlbums
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
                authenticate(credentials)
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

            it("should get artists") {
                authenticate(credentials)
                getArtists()
            }

            it("should get artist albums") {
                authenticate(credentials)
                let artists = getArtists()
                getArtistAlbums(artists[0].id!)
            }

            it("should download image") {
                authenticate(credentials)
                let artists = getArtists()
                var image: UIImage?
                service.downloadImage(artists[0].artworkUrl!, onSuccess: {
                    image = $0
                })
                expect(image).toEventuallyNot(beNil())
            }

            it("should download song") {
                authenticate(credentials)
                let artists = getArtists()
                let artistAlbums = getArtistAlbums(artists[0].id!)
                let filePath = FileUtils.generateTemporaryPath()
                var onProgressCalled = false
                var completed = false
                service.downloadSong(artistAlbums.albums![0].songs![0].url!, toFile: filePath, onProgress: {
                    progress in
                    onProgressCalled = true
                }, onSuccess: {
                    completed = true
                })
                expect(completed).toEventually(beTrue(), timeout: 10)
                expect(onProgressCalled).to(beTrue())
                expect(NSFileManager.defaultManager().fileExistsAtPath(filePath)).to(beTrue())
            }
        }
    }
}
