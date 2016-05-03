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

    func getArtists(onSuccess onSuccess: ([ArtistDto] -> Void)? = nil, onFailure: ([ErrorDto] -> Void)? = nil) {
        dispatch_async(queue) {
            do {
                let realm = try self.buildRealm()
                let artists = realm.objects(ArtistRealm).sorted("name").map { self.artistToDto($0) }
                dispatch_async(dispatch_get_main_queue()) {
                    onSuccess?(artists)
                }
            } catch {
                dispatch_async(dispatch_get_main_queue()) {
                    onFailure?([ErrorDto.unexpected])
                }
            }
        }
    }

    func getArtistAlbums(artistId: Int64, onSuccess: (ArtistAlbumsDto? -> Void)? = nil, onFailure: ([ErrorDto] -> Void)? = nil) {
        dispatch_async(queue) {
            do {
                let realm = try self.buildRealm()
                var artistAlbums: ArtistAlbumsDto? = nil
                if let artist = realm.objects(ArtistRealm).filter("id == \(artistId)").first {
                    let albumDtos: [AlbumSongsDto] = artist.albums.map {
                        album in
                        let songDtos = album.songs.map { self.songToDto($0) }
                        return AlbumSongsDto(album: self.albumToDto(album), songs: songDtos)
                    }
                    artistAlbums = ArtistAlbumsDto(artist: self.artistToDto(artist), albums: albumDtos)
                }
                dispatch_async(dispatch_get_main_queue()) {
                    onSuccess?(artistAlbums)
                }
            } catch {
                dispatch_async(dispatch_get_main_queue()) {
                    onFailure?([ErrorDto.unexpected])
                }
            }
        }
    }

    func saveSong(song: SongDto, onSuccess: (Void -> Void)? = nil, onFailure: ([ErrorDto] -> Void)? = nil) {
        // TODO: download artwork
        dispatch_async(queue) {
            do {
                let realm = try self.buildRealm()
                try realm.write {
                    realm.add(self.songFromDto(song), update: true)
                }
                dispatch_async(dispatch_get_main_queue()) {
                    onSuccess?()
                }
            } catch {
                dispatch_async(dispatch_get_main_queue()) {
                    onFailure?([ErrorDto.unexpected])
                }
            }
        }
    }

    func removeSong(songId: Int64, onSuccess: (Void -> Void)? = nil, onFailure: ([ErrorDto] -> Void)? = nil) {
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
                    // TODO: remove artwork if not used anymore
                    onSuccess?()
                }
            } catch {
                dispatch_async(dispatch_get_main_queue()) {
                    onFailure?([ErrorDto.unexpected])
                }
            }
        }
    }

    private func buildRealm() throws -> Realm {
        let config = Realm.Configuration(fileURL: NSURL(fileURLWithPath: FileUtils.pathInDocuments(realmFileName)))
        return try Realm(configuration: config)
    }

    private func genreFromDto(dto: GenreDto) -> GenreRealm {
        let genre = GenreRealm()
        genre.id = dto.id
        genre.name = dto.name
        genre.artwork.value = dto.artwork
        return genre
    }

    private func genreToDto(genre: GenreRealm) -> GenreDto {
        let dto = GenreDto(id: genre.id)
        dto.name = genre.name
        dto.artwork = genre.artwork.value
        dto.artworkUrl = buildArtworkPath(dto.artwork)
        return dto
    }

    private func artistFromDto(dto: ArtistDto) -> ArtistRealm {
        let artist = ArtistRealm()
        artist.id = dto.id
        artist.name = dto.name
        artist.artwork.value = dto.artwork
        return artist
    }

    private func artistToDto(artist: ArtistRealm) -> ArtistDto {
        let dto = ArtistDto(id: artist.id)
        dto.name = artist.name
        dto.artwork = artist.artwork.value
        dto.artworkUrl = buildArtworkPath(dto.artwork)
        return dto
    }

    private func albumFromDto(dto: AlbumDto) -> AlbumRealm {
        let album = AlbumRealm()
        album.id = dto.id
        album.name = dto.name
        album.year.value = dto.year
        album.artwork.value = dto.artwork
        album.artist = artistFromDto(dto.artist)
        return album
    }

    private func albumToDto(album: AlbumRealm) -> AlbumDto {
        let dto = AlbumDto(id: album.id, artist: artistToDto(album.artist))
        dto.name = album.name
        dto.year = album.year.value
        dto.artwork = album.artwork.value
        dto.artworkUrl = buildArtworkPath(dto.artwork)
        return dto
    }

    private func songFromDto(dto: SongDto) -> SongRealm {
        let song = SongRealm()
        song.id = dto.id
        song.updateDate = dto.updateDate
        song.size = dto.size
        song.duration = dto.duration
        song.discNumber.value = dto.discNumber
        song.trackNumber.value = dto.trackNumber
        song.artistName = dto.artistName
        song.name = dto.name
        song.album = albumFromDto(dto.album)
        song.genre = genreFromDto(dto.genre)
        return song
    }

    private func songToDto(song: SongRealm) -> SongDto {
        let dto = SongDto(id: song.id, album: albumToDto(song.album), genre: genreToDto(song.genre))
        dto.updateDate = song.updateDate
        dto.size = song.size
        dto.duration = song.duration
        dto.discNumber = song.discNumber.value
        dto.trackNumber = song.trackNumber.value
        dto.artistName = song.artistName
        dto.name = song.name
        return dto
    }

    private func buildArtworkPath(artwork: Int64?) -> String? {
        if let artwork = artwork {
            let path = NSString(string: artworkFolder).stringByAppendingPathComponent(String(artwork))
            return FileUtils.pathInDocuments(path)
        }
        return nil
    }
}
