//
// Created by Denis Dorokhov on 03/05/16.
// Copyright (c) 2016 Denis Dorokhov. All rights reserved.
//

import Foundation
import Quick
import Nimble
import ObjectMapper

@testable import Pony

class LibraryServiceDelegateMock: LibraryServiceDelegate {

    var didStartSongDownload: Song?
    var didProgressSongDownload: SongDownloadTask?
    var didCancelSongDownload: Song?
    var didFailSongDownload: (Song, [Error])?
    var didCompleteSongDownload: Song?
    var didDeleteSongDownload: Song?

    func libraryService(libraryService: LibraryService, didStartSongDownload song: Song) {
        didStartSongDownload = song
    }

    func libraryService(libraryService: LibraryService, didProgressSongDownload task: SongDownloadTask) {
        didProgressSongDownload = task
    }

    func libraryService(libraryService: LibraryService, didCancelSongDownload song: Song) {
        didCancelSongDownload = song
    }

    func libraryService(libraryService: LibraryService, didFail errors: [Error], songDownload song: Song) {
        didFailSongDownload = (song, errors)
    }

    func libraryService(libraryService: LibraryService, didCompleteSongDownload song: Song) {
        didCompleteSongDownload = song
    }

    func libraryService(libraryService: LibraryService, didDeleteSongDownload song: Song) {
        didDeleteSongDownload = song
    }
}

class LibraryServiceSpec: QuickSpec {
    override func spec() {
        describe("LibraryService") {

            var delegateMock: LibraryServiceDelegateMock!
            var service: LibraryService!
            beforeEach {
                TestUtils.cleanAll()

                let bundle = NSBundle(forClass: LibraryServiceSpec.self)

                let restServiceMock = RestServiceMock()
                restServiceMock.imagePath = bundle.pathForResource("artwork", ofType: "png")!
                restServiceMock.songPath = bundle.pathForResource("song", ofType: "mp3")!

                delegateMock = LibraryServiceDelegateMock()

                service = LibraryService()
                service.restService = restServiceMock
                service.addDelegate(delegateMock)
            }
            afterEach {
                service.removeDelegate(delegateMock)
                TestUtils.cleanAll()
            }

            let buildSongMock: Void -> Song = {
                let bundle = NSBundle(forClass: LibraryServiceSpec.self)
                let json = try! String(contentsOfFile: bundle.pathForResource("song", ofType: "json")!)
                return Mapper<Song>().map(json)!
            }
            let stringToUrl: String? -> NSURL? = {
                if let url = $0 {
                    return NSURL(string: url)
                } else {
                    return nil
                }
            }

            it("should download song and artworks") {
                var progress: Float?
                var song: Song?
                service.downloadSong(buildSongMock(), onProgress: {
                    progress = $0
                }, onSuccess: {
                    song = $0
                })
                expect(song).toEventuallyNot(beNil())
                expect(progress).toNot(beNil())
                expect(delegateMock.didStartSongDownload).toNot(beNil())
                expect(delegateMock.didProgressSongDownload).toNot(beNil())
                expect(delegateMock.didCompleteSongDownload).toNot(beNil())
                if let song = song {
                    if let artistArtworkPath = stringToUrl(song.album.artist.artworkUrl)?.path,
                            albumArtworkPath = stringToUrl(song.album.artworkUrl)?.path {

                        let fileManager = NSFileManager.defaultManager()

                        expect(fileManager.fileExistsAtPath(artistArtworkPath)).to(beTrue())
                        expect(fileManager.fileExistsAtPath(albumArtworkPath)).to(beTrue())

                    } else {
                        fail()
                    }
                }
            }

            it("should fetch artists and albums") {
                waitUntil {
                    done in
                    service.downloadSong(buildSongMock(), onSuccess: {
                        song in
                        done()
                    })
                }
                var artists: [Artist]?
                service.getArtists(onSuccess: {
                    artists = $0
                })
                expect(artists).toEventuallyNot(beNil())
                expect(artists).to(haveCount(1))
                if let artists = artists where artists.count > 0 {
                    var artistAlbums: ArtistAlbums?
                    service.getArtistAlbums(artists[0].id, onSuccess: {
                        artistAlbums = $0
                    })
                    expect(artistAlbums).toEventuallyNot(beNil())
                    if let artistAlbums = artistAlbums where artistAlbums.albums.count > 0 {
                        expect(artistAlbums.albums).to(haveCount(1))
                        expect(artistAlbums.albums[0].songs).to(haveCount(1))
                    } else {
                        fail()
                    }
                }
            }

            it("should manage song download tasks") {
                let song = buildSongMock()
                service.downloadSong(song)
                expect(service.allTasks()).to(haveCount(1))
                expect(service.taskForSong(song.id)).toNot(beNil())
            }

            it("should cancel song download") {
                let song = buildSongMock()
                service.downloadSong(song)
                service.cancelSongDownload(song.id)
                expect(delegateMock.didCancelSongDownload).toNot(beNil())
                expect(service.allTasks()).to(haveCount(0))
                expect(service.taskForSong(song.id)).to(beNil())
            }

            it("should delete song, album, artist and artworks") {
                let song = buildSongMock()
                waitUntil {
                    done in
                    service.downloadSong(song, onSuccess: {
                        song in
                        done()
                    })
                }
                var deletedSong: Song?
                service.deleteSong(song.id, onSuccess: {
                    deletedSong = $0
                })
                expect(deletedSong).toEventuallyNot(beNil())
                expect(delegateMock.didDeleteSongDownload).toNot(beNil())

                var artists: [Artist]?
                service.getArtists(onSuccess: {
                    artists = $0
                })
                expect(artists).toEventuallyNot(beNil())
                expect(artists).to(haveCount(0))

                if let deletedSong = deletedSong {
                    if let artistArtworkPath = stringToUrl(deletedSong.album.artist.artworkUrl)?.path,
                            albumArtworkPath = stringToUrl(deletedSong.album.artworkUrl)?.path {

                        let fileManager = NSFileManager.defaultManager()

                        expect(fileManager.fileExistsAtPath(artistArtworkPath)).to(beFalse())
                        expect(fileManager.fileExistsAtPath(albumArtworkPath)).to(beFalse())

                    } else {
                        fail()
                    }
                }
            }

            // TODO: test case with no artwork
            // TODO: test error handling
        }
    }
}
