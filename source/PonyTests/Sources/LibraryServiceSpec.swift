//
// Created by Denis Dorokhov on 03/05/16.
// Copyright (c) 2016 Denis Dorokhov. All rights reserved.
//

import Foundation
import Quick
import Nimble
import ObjectMapper

@testable import Pony

class LibraryServiceSpec: QuickSpec {
    override func spec() {
        describe("LibraryService") {

            var service: LibraryService!
            beforeEach {
                TestUtils.cleanAll()

                let bundle = NSBundle(forClass: LibraryServiceSpec.self)

                let restServiceMock = RestServiceMock()
                restServiceMock.imagePath = bundle.pathForResource("artwork", ofType: "png")!
                restServiceMock.songPath = bundle.pathForResource("song", ofType: "mp3")!

                service = LibraryService()
                service.restService = restServiceMock
            }
            afterEach {
                TestUtils.cleanAll()
            }

            let buildSongMock: Void -> Song = {
                let bundle = NSBundle(forClass: LibraryServiceSpec.self)
                let json = try! String(contentsOfFile: bundle.pathForResource("song", ofType: "json")!)
                return Mapper<Song>().map(json)!
            }

            it("should download song") {
                var didProgress = false
                waitUntil {
                    done in
                    service.downloadSong(buildSongMock(), onProgress: {
                        progress in
                        didProgress = true
                    }, onSuccess: {
                        song in
                        done()
                    })
                }
                expect(didProgress).to(beTrue())
                var artists: [Artist]?
                service.getArtists(onSuccess: {
                    artists = $0
                })
                expect(artists).toEventuallyNot(beNil())
                expect(artists).to(haveCount(1))
                var artistAlbums: ArtistAlbums?
                service.getArtistAlbums(artists![0].id, onSuccess: {
                    artistAlbums = $0
                })
                expect(artistAlbums).toEventuallyNot(beNil())
                expect(artistAlbums!.albums).to(haveCount(1))
                expect(artistAlbums!.albums[0].songs).to(haveCount(1))
            }

            it("should delete song, album and artist") {
                let song = buildSongMock()
                waitUntil {
                    done in
                    service.downloadSong(song, onSuccess: {
                        song in
                        done()
                    })
                }
                var artists: [Artist]?
                service.getArtists(onSuccess: {
                    artists = $0
                })
                expect(artists).toEventuallyNot(beNil())
                waitUntil {
                    done in
                    service.deleteSong(song.id, onSuccess: {
                        song in
                        done()
                    })
                }
                artists = nil
                service.getArtists(onSuccess: {
                    artists = $0
                })
                expect(artists).toEventuallyNot(beNil())
                expect(artists).to(haveCount(0))
            }
        }
    }
}
