//
// Created by Denis Dorokhov on 02/05/16.
// Copyright (c) 2016 Denis Dorokhov. All rights reserved.
//

import Foundation
import RealmSwift
import XCGLogger
import OrderedSet
import Async

class SongDownloadTask: Hashable {

    let song: Song

    private(set) var progress: Float = 0

    private var albumArtworkPath: String
    private var artistArtworkPath: String
    private var songPath: String

    private var request: RestRequest?

    init(song: Song, albumArtworkPath: String, artistArtworkPath: String, songPath: String) {
        self.song = song
        self.albumArtworkPath = albumArtworkPath
        self.artistArtworkPath = artistArtworkPath
        self.songPath = songPath
    }

    var hashValue: Int {
        return song.id.hashValue
    }
}

func ==(lhs: SongDownloadTask, rhs: SongDownloadTask) -> Bool {
    return lhs.song.id == rhs.song.id
}

protocol LibraryServiceDelegate: class {
    func libraryService(libraryService: LibraryService, didStartSongDownload song: Song)
    func libraryService(libraryService: LibraryService, didProgressSongDownload task: SongDownloadTask)
    func libraryService(libraryService: LibraryService, didCancelSongDownload song: Song)
    func libraryService(libraryService: LibraryService, didFail errors: [Error], songDownload song: Song)
    func libraryService(libraryService: LibraryService, didCompleteSongDownload song: Song)
    func libraryService(libraryService: LibraryService, didDeleteSongDownload song: Song)
}

class LibraryService {

    private let log = XCGLogger.defaultInstance()

    var restService: RestService!

    var realmFileName: String = "library.realm"
    var artworkDownloadFolder: String = "Artwork"
    var songDownloadFolder: String = "Songs"

    private var realmQueue = dispatch_queue_create("LibraryService.realmQueue", DISPATCH_QUEUE_SERIAL)

    private var delegates: OrderedSet<NSValue> = []

    private var songDownloadTasks: OrderedSet<SongDownloadTask> = []
    private var songToDownloadTask: [Int64: SongDownloadTask] = [:]

    func addDelegate(delegate: LibraryServiceDelegate) {
        delegates.append(NSValue(nonretainedObject: delegate))
    }

    func removeDelegate(delegate: LibraryServiceDelegate) {
        delegates.remove(NSValue(nonretainedObject: delegate))
    }

    func getArtists(onSuccess onSuccess: ([Artist] -> Void)? = nil, onFailure: ([Error] -> Void)? = nil) {
        Async.customQueue(realmQueue) {
            do {
                let realm = try self.buildRealm()
                let artists = realm.objects(ArtistRealm).sorted("name").map {
                    $0.toArtist(artworkUrl: self.buildArtworkUrl)
                }
                Async.main {
                    onSuccess?(artists)
                }
            } catch let error {
                self.log.error("Could not fetch artists: \(error).")
                Async.main {
                    onFailure?([Error.unexpected])
                }
            }
        }
    }

    func getArtistAlbums(artistId: Int64, onSuccess: (ArtistAlbums -> Void)? = nil, onFailure: ([Error] -> Void)? = nil) {
        Async.customQueue(realmQueue) {
            do {
                let realm = try self.buildRealm()
                var artistAlbums: ArtistAlbums? = nil
                if let artist = realm.objects(ArtistRealm).filter("id == \(artistId)").first {
                    let albums: [AlbumSongs] = artist.albums.map {
                        album in
                        let songs = album.songs.map {
                            $0.toSong(artworkUrl: self.buildArtworkUrl, songUrl: self.buildSongUrl)
                        }
                        return AlbumSongs(album: album.toAlbum(artworkUrl: self.buildArtworkUrl), songs: songs)
                    }
                    artistAlbums = ArtistAlbums(artist: artist.toArtist(artworkUrl: self.buildArtworkUrl), albums: albums)
                }
                Async.main {
                    if let artistAlbums = artistAlbums {
                        onSuccess?(artistAlbums)
                    } else {
                        onFailure?([Error(code: Error.CODE_ARTIST_NOT_FOUND, text: "Artist not found.")])
                    }
                }
            } catch let error {
                self.log.error("Could not fetch albums: \(error).")
                Async.main {
                    onFailure?([Error.unexpected])
                }
            }
        }
    }

    func downloadSong(song: Song, onProgress: (Float -> Void)? = nil,
                      onSuccess: (Song -> Void)? = nil,
                      onFailure: ([Error] -> Void)? = nil) {

        if let task = songToDownloadTask[song.id] {
            log.info("Song '\(song.id)' is already downloading, cancelling download.")
            doCancelSongDownload(task)
        }

        let task = SongDownloadTask(song: song,
                albumArtworkPath: FileUtils.generateTemporaryPath(),
                artistArtworkPath: FileUtils.generateTemporaryPath(),
                songPath: FileUtils.generateTemporaryPath())

        songDownloadTasks.append(task)
        songToDownloadTask[song.id] = task

        // TODO: avoid downloading the same artwork two times (when artist and album artwork is the same)
        let taskChain = TaskChain()
        taskChain.addTask {
            next, cancel in
            self.doDownloadAlbumArtwork(task, onSuccess: {
                next()
            }, onCancellation: {
                cancel()
            }, onFailure: {
                cancel()
                self.failSongDownload(task, errors: $0)
                onFailure?($0)
            })
        }
        taskChain.addTask {
            next, cancel in
            self.doDownloadArtistArtwork(task, onSuccess: {
                next()
            }, onCancellation: {
                cancel()
            }, onFailure: {
                cancel()
                self.failSongDownload(task, errors: $0)
                onFailure?($0)
            })
        }
        taskChain.addTask {
            next, cancel in
            self.doDownloadSong(task, onProgress: {
                task.progress = $0
                onProgress?($0)
                for delegate in self.fetchDelegates() {
                    delegate.libraryService(self, didProgressSongDownload: task)
                }
            }, onSuccess: {
                next()
                self.finishSongDownload(task, onSuccess: onSuccess, onFailure: {
                    self.failSongDownload(task, errors: $0)
                    onFailure?($0)
                })
            }, onCancellation: {
                cancel()
            }, onFailure: {
                cancel()
                self.failSongDownload(task, errors: $0)
                onFailure?($0)
            })
        }

        log.info("Song '\(song.id)' download started.")

        for delegate in fetchDelegates() {
            delegate.libraryService(self, didStartSongDownload: task.song)
        }
    }

    func cancelSongDownload(songId: Int64) {
        if let task = songToDownloadTask[songId] {
            doCancelSongDownload(task)
            log.info("Download cancelled for song '\(task.song.id)'.")
        } else {
            log.warning("Could not cancel download of song '\(songId)': download is not started.")
        }
    }

    func taskForSong(songId: Int64) -> SongDownloadTask? {
        return songToDownloadTask[songId]
    }

    func allTasks() -> [SongDownloadTask] {
        return Array(songDownloadTasks)
    }

    func deleteSong(songId: Int64, onSuccess: (Song -> Void)? = nil, onFailure: ([Error] -> Void)? = nil) {
        Async.customQueue(realmQueue) {
            do {
                let realm = try self.buildRealm()
                let songRealm = realm.objects(SongRealm).filter("id == \(songId)").first
                var song: Song?
                if let songRealm = songRealm {
                    song = songRealm.toSong(artworkUrl: self.buildArtworkUrl, songUrl: self.buildSongUrl)
                    try realm.write {
                        self.doDeleteSong(songRealm, realm: realm)
                    }
                }
                Async.main {
                    if let song = song {
                        self.log.info("Song download '\(song.id)' deleted.")
                        onSuccess?(song)
                        for delegate in self.fetchDelegates() {
                            delegate.libraryService(self, didDeleteSongDownload: song)
                        }
                    } else {
                        self.log.error("Could not delete song '\(songId)': song download not found.")
                        onFailure?([Error(code: Error.CODE_SONG_NOT_FOUND, text: "Song not found.")])
                    }
                }
            } catch let error {
                self.log.error("Could not delete song: \(error).")
                Async.main {
                    onFailure?([Error.unexpected])
                }
            }
        }
    }

    private func doDeleteSong(song: SongRealm, realm: Realm) {
        var albumToDelete: AlbumRealm?, artistToDelete: ArtistRealm?
        var artworksToCheck: [Int64] = []
        if song.album.songs.count == 1 {
            albumToDelete = song.album
            if let artwork = song.album.artwork.value {
                artworksToCheck.append(artwork)
            }
            if song.album.artist.albums.count == 1 {
                artistToDelete = song.album.artist
                if let artwork = song.album.artist.artwork.value {
                    artworksToCheck.append(artwork)
                }
            }
        }
        let songPath = buildSongPath(song.id)
        realm.delete(song)
        let _ = try? NSFileManager.defaultManager().removeItemAtPath(songPath)
        if let albumToDelete = albumToDelete {
            realm.delete(albumToDelete)
        }
        if let artistToDelete = artistToDelete {
            realm.delete(artistToDelete)
        }
        for artwork in artworksToCheck {
            if realm.objects(AlbumRealm).filter("artwork == \(artwork)").count == 0 &&
                    realm.objects(ArtistRealm).filter("artwork == \(artwork)").count == 0 {
                if let artworkPath = buildArtworkPath(artwork) {
                    let _ = try? NSFileManager.defaultManager().removeItemAtPath(artworkPath)
                }
            }
        }
    }

    private func saveSong(song: Song, onSuccess: (Song -> Void)? = nil, onFailure: ([Error] -> Void)? = nil) {
        Async.customQueue(realmQueue) {
            do {
                let realm = try self.buildRealm()
                let songRealm = SongRealm(song: song)
                try realm.write {
                    realm.add(songRealm, update: true)
                }
                let song = songRealm.toSong(artworkUrl: self.buildArtworkUrl, songUrl: self.buildSongUrl)
                Async.main {
                    onSuccess?(song)
                }
            } catch let error {
                self.log.error("Could not save song: \(error).")
                Async.main {
                    onFailure?([Error.unexpected])
                }
            }
        }
    }

    private func doDownloadAlbumArtwork(task: SongDownloadTask,
                                        onSuccess: Void -> Void,
                                        onCancellation: Void -> Void,
                                        onFailure: [Error] -> Void) {
        if let artwork = task.song.album.artwork, url = task.song.album.artworkUrl, path = buildArtworkPath(artwork) {
            task.request = doDownloadArtwork(artwork, url: url, path: path, onSuccess: {
                do {
                    try NSFileManager.defaultManager().moveItemAtPath($0, toPath: task.albumArtworkPath)
                    onSuccess()
                } catch let error {
                    self.log.error("Could not move downloaded album artwork file '\($0)': \(error).")
                    onFailure([Error.unexpected])
                }
            }, onCancellation: onCancellation, onFailure: onFailure)
        } else {
            log.debug("No artwork for album '\(task.song.album.id)'.")
            onSuccess()
        }
    }

    private func doDownloadArtistArtwork(task: SongDownloadTask,
                                         onSuccess: Void -> Void,
                                         onCancellation: Void -> Void,
                                         onFailure: [Error] -> Void) {
        if let artwork = task.song.album.artist.artwork, url = task.song.album.artist.artworkUrl, path = buildArtworkPath(artwork) {
            task.request = doDownloadArtwork(artwork, url: url, path: path, onSuccess: {
                do {
                    try NSFileManager.defaultManager().moveItemAtPath($0, toPath: task.artistArtworkPath)
                    onSuccess()
                } catch let error {
                    self.log.error("Could not move downloaded artist artwork file '\($0)': \(error).")
                    onFailure([Error.unexpected])
                }
            }, onCancellation: onCancellation, onFailure: onFailure)
        } else {
            log.debug("No artwork for artist '\(task.song.album.artist.id)'.")
            onSuccess()
        }
    }

    private func doDownloadArtwork(artwork: Int64, url: String, path: String,
                                   onSuccess: String -> Void,
                                   onCancellation: Void -> Void,
                                   onFailure: [Error] -> Void) -> RestRequest? {
        if !NSFileManager.defaultManager().fileExistsAtPath(path) {
            return restService.downloadImage(url, onSuccess: {
                self.log.info("Artwork '\(artwork)' has been downloaded.")
                if let imageData = UIImagePNGRepresentation($0) {
                    let filePath = FileUtils.generateTemporaryPath()
                    if imageData.writeToFile(filePath, atomically: true) {
                        onSuccess(filePath)
                    } else {
                        self.log.error("Artwork '\(artwork)' could not be written to file.")
                        onFailure([Error.unexpected])
                    }
                } else {
                    self.log.error("Artwork '\(artwork)' could not be encoded into PNG.")
                    onFailure([Error.unexpected])
                }
            }, onFailure: {
                if Error.fetchFirstByCodes([Error.CODE_CLIENT_REQUEST_CANCELLED], fromArray: $0) != nil {
                    onCancellation()
                } else {
                    onFailure($0)
                }
            })
        } else {
            log.debug("Artwork '\(artwork)' already exists.")
            Async.background {
                let filePath = FileUtils.generateTemporaryPath()
                do {
                    try NSFileManager.defaultManager().copyItemAtPath(path, toPath: filePath)
                    Async.main {
                        onSuccess(filePath)
                    }
                } catch let error {
                    self.log.error("Could not copy stored artwork file '\(path)': \(error).")
                    Async.main {
                        onFailure([Error.unexpected])
                    }
                }
            }
        }
        return nil
    }

    private func doDownloadSong(task: SongDownloadTask,
                                onProgress: (Float -> Void)?,
                                onSuccess: Void -> Void,
                                onCancellation: Void -> Void,
                                onFailure: [Error] -> Void) {
        task.request = restService.downloadSong(task.song.url, toFile: task.songPath, onProgress: onProgress, onSuccess: {
            self.log.info("Song '\(task.song.url)' has been downloaded.")
            onSuccess()
        }, onFailure: {
            if Error.fetchFirstByCodes([Error.CODE_CLIENT_REQUEST_CANCELLED], fromArray: $0) != nil {
                onCancellation()
            } else {
                onFailure($0)
            }
        })
    }

    private func doCancelSongDownload(task: SongDownloadTask) {
        task.request?.cancel()
        cleanSongDownload(task)
        for delegate in fetchDelegates() {
            delegate.libraryService(self, didCancelSongDownload: task.song)
        }
    }

    private func failSongDownload(task: SongDownloadTask, errors: [Error]) {
        cleanSongDownload(task)
        log.error("Song '\(task.song.id)' download failed: \(errors)")
        for delegate in fetchDelegates() {
            delegate.libraryService(self, didFail: errors, songDownload: task.song)
        }
    }

    private func finishSongDownload(task: SongDownloadTask, onSuccess: (Song -> Void)?, onFailure: ([Error] -> Void)?) {
        do {

            if let artworkPath = buildArtworkPath(task.song.album.artwork) {
                try moveArtwork(task.albumArtworkPath, toPath: artworkPath)
            }
            if let artworkPath = buildArtworkPath(task.song.album.artist.artwork) {
                try moveArtwork(task.artistArtworkPath, toPath: artworkPath)
            }

            let songPath = buildSongPath(task.song.id)
            try FileUtils.createDirectory(NSString(string: songPath).stringByDeletingLastPathComponent)
            let _ = try? NSFileManager.defaultManager().removeItemAtPath(songPath)
            try NSFileManager.defaultManager().moveItemAtPath(task.songPath, toPath: songPath)
            try NSURL(fileURLWithPath: songPath).setResourceValue(true, forKey: NSURLIsExcludedFromBackupKey)

            saveSong(task.song, onSuccess: {
                self.songDownloadTasks.remove(task)
                self.songToDownloadTask.removeValueForKey(task.song.id)
                self.log.info("Song '\($0.id)' download complete.")
                onSuccess?($0)
                for delegate in self.fetchDelegates() {
                    delegate.libraryService(self, didCompleteSongDownload: $0)
                }
            }, onFailure: onFailure)

        } catch let error {
            log.error("Could not move song files: \(error).")
            onFailure?([Error.unexpected])
        }
    }

    private func moveArtwork(fromPath: String, toPath: String) throws {
        try FileUtils.createDirectory(NSString(string: toPath).stringByDeletingLastPathComponent)
        let _ = try? NSFileManager.defaultManager().removeItemAtPath(toPath)
        try NSFileManager.defaultManager().moveItemAtPath(fromPath, toPath: toPath)
        try NSURL(fileURLWithPath: toPath).setResourceValue(true, forKey: NSURLIsExcludedFromBackupKey)
    }

    private func cleanSongDownload(task: SongDownloadTask) {

        let fileManager = NSFileManager.defaultManager()

        let _ = try? fileManager.removeItemAtPath(task.albumArtworkPath)
        let _ = try? fileManager.removeItemAtPath(task.artistArtworkPath)
        let _ = try? fileManager.removeItemAtPath(task.songPath)

        songDownloadTasks.remove(task)
        songToDownloadTask.removeValueForKey(task.song.id)
    }

    private func buildRealm() throws -> Realm {
        let config = Realm.Configuration(fileURL: NSURL(fileURLWithPath: FileUtils.pathInDocuments(realmFileName)))
        return try Realm(configuration: config)
    }

    private func buildSongPath(songId: Int64) -> String {
        let path = NSString(string: songDownloadFolder).stringByAppendingPathComponent(String(songId))
        return FileUtils.pathInDocuments(path)
    }

    private func buildSongUrl(songId: Int64) -> String {
        return NSURL(fileURLWithPath: buildSongPath(songId)).absoluteString
    }

    private func buildArtworkPath(artworkId: Int64?) -> String? {
        if let artworkId = artworkId {
            let path = NSString(string: artworkDownloadFolder).stringByAppendingPathComponent(String(artworkId))
            return FileUtils.pathInDocuments(path)
        }
        return nil
    }

    private func buildArtworkUrl(artworkId: Int64?) -> String? {
        if let artworkPath = buildArtworkPath(artworkId) {
            return NSURL(fileURLWithPath: artworkPath).absoluteString
        }
        return nil
    }

    private func fetchDelegates() -> [LibraryServiceDelegate] {
        return delegates.map { $0.nonretainedObjectValue as! LibraryServiceDelegate }
    }
}
