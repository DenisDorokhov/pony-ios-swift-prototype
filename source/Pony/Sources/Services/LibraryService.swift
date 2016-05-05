//
// Created by Denis Dorokhov on 02/05/16.
// Copyright (c) 2016 Denis Dorokhov. All rights reserved.
//

import Foundation
import RealmSwift
import XCGLogger

class LibraryService {

    private let log = XCGLogger.defaultInstance()

    var realmFileName: String = "library.realm"
    var artworkFolder: String = "Artwork"

    private var queue = dispatch_queue_create("LibraryService.queue", nil)

    func getArtists(onSuccess onSuccess: ([Artist] -> Void)? = nil, onFailure: ([Error] -> Void)? = nil) {
        dispatch_async(queue) {
            do {
                let realm = try self.buildRealm()
                let artists = realm.objects(ArtistRealm).sorted("name").map { self.realmToArtist($0) }
                dispatch_async(dispatch_get_main_queue()) {
                    onSuccess?(artists)
                }
            } catch {
                dispatch_async(dispatch_get_main_queue()) {
                    onFailure?([Error.unexpected])
                }
            }
        }
    }

    func getArtistAlbums(artistId: Int64, onSuccess: (ArtistAlbums? -> Void)? = nil, onFailure: ([Error] -> Void)? = nil) {
        dispatch_async(queue) {
            do {
                let realm = try self.buildRealm()
                var artistAlbums: ArtistAlbums? = nil
                if let artist = realm.objects(ArtistRealm).filter("id == \(artistId)").first {
                    let albumDtos: [AlbumSongs] = artist.albums.map {
                        album in
                        let songDtos = album.songs.map { self.realmToSong($0) }
                        return AlbumSongs(album: self.realmToAlbum(album), songs: songDtos)
                    }
                    artistAlbums = ArtistAlbums(artist: self.realmToArtist(artist), albums: albumDtos)
                }
                dispatch_async(dispatch_get_main_queue()) {
                    onSuccess?(artistAlbums)
                }
            } catch {
                dispatch_async(dispatch_get_main_queue()) {
                    onFailure?([Error.unexpected])
                }
            }
        }
    }

    func saveSong(song: Song, onSuccess: (Void -> Void)? = nil, onFailure: ([Error] -> Void)? = nil) {
        dispatch_async(queue) {
            do {
                let realm = try self.buildRealm()
                try realm.write {
                    realm.add(self.songToRealm(song), update: true)
                }
                dispatch_async(dispatch_get_main_queue()) {
                    onSuccess?()
                }
            } catch {
                dispatch_async(dispatch_get_main_queue()) {
                    onFailure?([Error.unexpected])
                }
            }
        }
    }

    func removeSong(songId: Int64, onSuccess: (Void -> Void)? = nil, onFailure: ([Error] -> Void)? = nil) {
        dispatch_async(queue) {
            do {
                let realm = try self.buildRealm()
                if let song = realm.objects(SongRealm).filter("id == \(songId)").first {
                    try realm.write {
                        var albumToDelete: AlbumRealm?
                        var artistToDelete: ArtistRealm?
                        if song.album.songs.count == 1 {
                            albumToDelete = song.album
                            if song.album.artist.albums.count == 1 {
                                artistToDelete = song.album.artist
                            }
                        }
                        realm.delete(song)
                        if let albumToDelete = albumToDelete {
                            realm.delete(albumToDelete)
                        }
                        if let artistToDelete = artistToDelete {
                            realm.delete(artistToDelete)
                        }
                    }
                }
                dispatch_async(dispatch_get_main_queue()) {
                    onSuccess?()
                }
            } catch {
                dispatch_async(dispatch_get_main_queue()) {
                    onFailure?([Error.unexpected])
                }
            }
        }
    }

    private func buildRealm() throws -> Realm {
        let config = Realm.Configuration(fileURL: NSURL(fileURLWithPath: FileUtils.pathInDocuments(realmFileName)))
        return try Realm(configuration: config)
    }

    private func genreToRealm(genre: Genre) -> GenreRealm {
        let realm = GenreRealm()
        realm.id = genre.id
        realm.name = genre.name
        realm.artwork.value = genre.artwork
        return realm
    }

    private func realmToGenre(realm: GenreRealm) -> Genre {
        let genre = Genre(id: realm.id)
        genre.name = realm.name
        genre.artwork = realm.artwork.value
        genre.artworkUrl = buildArtworkPath(genre.artwork)
        return genre
    }

    private func artistToRealm(artist: Artist) -> ArtistRealm {
        let realm = ArtistRealm()
        realm.id = artist.id
        realm.name = artist.name
        realm.artwork.value = artist.artwork
        return realm
    }

    private func realmToArtist(realm: ArtistRealm) -> Artist {
        let artist = Artist(id: realm.id)
        artist.name = realm.name
        artist.artwork = realm.artwork.value
        artist.artworkUrl = buildArtworkPath(artist.artwork)
        return artist
    }

    private func albumToRealm(album: Album) -> AlbumRealm {
        let realm = AlbumRealm()
        realm.id = album.id
        realm.name = album.name
        realm.year.value = album.year
        realm.artwork.value = album.artwork
        realm.artist = artistToRealm(album.artist)
        return realm
    }

    private func realmToAlbum(realm: AlbumRealm) -> Album {
        let album = Album(id: realm.id, artist: realmToArtist(realm.artist))
        album.name = realm.name
        album.year = realm.year.value
        album.artwork = realm.artwork.value
        album.artworkUrl = buildArtworkPath(album.artwork)
        return album
    }

    private func songToRealm(song: Song) -> SongRealm {
        let realm = SongRealm()
        realm.id = song.id
        realm.updateDate = song.updateDate
        realm.size = song.size
        realm.duration = song.duration
        realm.discNumber.value = song.discNumber
        realm.trackNumber.value = song.trackNumber
        realm.artistName = song.artistName
        realm.name = song.name
        realm.album = albumToRealm(song.album)
        realm.genre = genreToRealm(song.genre)
        return realm
    }

    private func realmToSong(realm: SongRealm) -> Song {
        let song = Song(id: realm.id, album: realmToAlbum(realm.album), genre: realmToGenre(realm.genre))
        song.updateDate = realm.updateDate
        song.size = realm.size
        song.duration = realm.duration
        song.discNumber = realm.discNumber.value
        song.trackNumber = realm.trackNumber.value
        song.artistName = realm.artistName
        song.name = realm.name
        return song
    }

    private func buildArtworkPath(artwork: Int64?) -> String? {
        if let artwork = artwork {
            let path = NSString(string: artworkFolder).stringByAppendingPathComponent(String(artwork))
            return FileUtils.pathInDocuments(path)
        }
        return nil
    }
}
