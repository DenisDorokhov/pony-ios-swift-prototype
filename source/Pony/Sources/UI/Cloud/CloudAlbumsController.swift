//
// Created by Denis Dorokhov on 12/05/16.
// Copyright (c) 2016 Denis Dorokhov. All rights reserved.
//

import UIKit
import Localize_Swift
import XCGLogger

class CloudAlbumsController: UITableViewController, LibraryServiceDelegate {

    private let log = XCGLogger.defaultInstance()

    var restService: RestService!
    var errorNotifier: ErrorNotifier!
    var libraryService: LibraryService! {
        didSet {
            libraryService.addDelegate(self)
        }
    }

    var artist: Artist? {
        didSet {
            if let artist = artist {
                title = artist.name ?? Localized("Unknown")
            } else {
                title = nil
            }
            loadAlbums()
        }
    }
    var downloadedArtistSongs: Set<Song>?

    @IBInspectable var albumCellHeight: CGFloat = 44
    @IBInspectable var songCellHeight: CGFloat = 44
    @IBInspectable var discSongCellHeight: CGFloat = 44

    private var albumDiscsToSongs: [[Int: [Song]]] = []
    private var artistAlbums: ArtistAlbums? {
        didSet {
            albumDiscsToSongs.removeAll()
            for albumSongs in artistAlbums?.albums ?? [] {
                var discToSongs: [Int: [Song]] = [:]
                for song in albumSongs.songs {
                    let discNumber = song.discNumber ?? 1
                    var discSongs = discToSongs[discNumber] ?? []
                    discSongs.append(song)
                    discToSongs[discNumber] = discSongs
                }
                albumDiscsToSongs.append(discToSongs)
            }
        }
    }

    private var currentRequest: RestRequest?

    deinit {
        libraryService.removeDelegate(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView()
    }

    // MARK: LibraryServiceDelegate

    func libraryService(libraryService: LibraryService, didFail errors: [Error], songDownload song: Song) {}

    func libraryService(libraryService: LibraryService, didStartSongDownload song: Song) {
        for cell in tableView.visibleCells {
            if let songCell = cell as? SongCell where songCell.song?.id == song.id {
                songCell.state = .Downloading(0)
            }
        }
    }

    func libraryService(libraryService: LibraryService, didCancelSongDownload song: Song) {
        for cell in tableView.visibleCells {
            if let songCell = cell as? SongCell where songCell.song?.id == song.id {
                songCell.state = .Cloud
            }
        }
    }

    func libraryService(libraryService: LibraryService, didProgressSongDownload task: SongDownloadTask) {
        for cell in tableView.visibleCells {
            if let songCell = cell as? SongCell where songCell.song?.id == task.song.id {
                songCell.state = .Downloading(task.progress)
            }
        }
    }

    func libraryService(libraryService: LibraryService, didCompleteSongDownload song: Song) {
        if downloadedArtistSongs != nil {
            downloadedArtistSongs!.insert(song)
            for cell in tableView.visibleCells {
                if let songCell = cell as? SongCell where songCell.song?.id == song.id {
                    songCell.state = .Downloaded
                }
            }
        }
    }

    func libraryService(libraryService: LibraryService, didDeleteSongDownload song: Song) {
        if downloadedArtistSongs != nil {
            downloadedArtistSongs!.remove(song)
            for cell in tableView.visibleCells {
                if let songCell = cell as? SongCell where songCell.song?.id == song.id {
                    songCell.state = .Cloud
                }
            }
        }
    }

    // MARK: UITableViewDataSource

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return artistAlbums?.albums.count ?? 0
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return artistAlbums?.albums[section].songs.count ?? 0
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let albumSongs = artistAlbums!.albums[indexPath.section]
        let song = albumSongs.songs[indexPath.row]
        let isCellWithDiscNumber = shouldSong(song, renderDiscNumberAtAlbumIndex: indexPath.section)
        let songCell: SongCell
        if (isCellWithDiscNumber) {
            songCell = tableView.dequeueReusableCellWithIdentifier("discSongCell") as! DiscSongCell
        } else {
            songCell = tableView.dequeueReusableCellWithIdentifier("songCell") as! SongCell
        }
        songCell.song = song
        // TODO: check if song is playing
        if downloadedArtistSongs?.contains(song) ?? false {
            songCell.state = .Downloaded
        } else if let task = libraryService.taskForSong(song.id) {
            songCell.state = .Downloading(task.progress)
        } else {
            songCell.state = .Cloud
        }
        return songCell
    }

    // MARK: UITableViewDelegate

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        let albumSongs = artistAlbums!.albums[indexPath.section]
        let song = albumSongs.songs[indexPath.row]
        // TODO: check if song is playing
        if downloadedArtistSongs?.contains(song) ?? false {
            libraryService.deleteSong(song.id)
        } else if let _ = libraryService.taskForSong(song.id) {
            libraryService.cancelSongDownload(song.id)
        } else {
            libraryService.downloadSong(song)
        }
    }

    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let albumSongs = artistAlbums!.albums[section]
        let albumCell = tableView.dequeueReusableCellWithIdentifier("albumCell") as! AlbumCell
        albumCell.albumSongs = albumSongs
        return albumCell.contentView;
    }

    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return albumCellHeight
    }

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let albumSongs = artistAlbums?.albums[indexPath.section]
        let song = albumSongs!.songs[indexPath.row]
        let isCellWithDiscNumber = shouldSong(song, renderDiscNumberAtAlbumIndex: indexPath.section)
        return isCellWithDiscNumber ? discSongCellHeight : songCellHeight
    }

    // MARK: Private

    private func loadAlbums() {
        currentRequest?.cancel()
        currentRequest = nil
        if let artist = artist {
            let doLoadAlbums = {
                self.log.info("Loading albums of artist '\(artist.id)'...")
                self.currentRequest = self.restService.getArtistAlbums(artist.id, onSuccess: {
                    self.currentRequest = nil
                    self.artistAlbums = $0
                    self.refreshControl?.endRefreshing()
                    self.tableView.reloadData()
                    self.log.info("\($0.albums.count) albums of artist '\($0.artist.id)' loaded.")
                }, onFailure: {
                    if Error.fetchFirstByCodes([Error.CODE_CLIENT_REQUEST_CANCELLED], fromArray: $0) != nil {
                        self.log.debug("Cancelled loading albums of artist '\(artist.id)'.")
                    } else {
                        self.currentRequest = nil
                        self.log.error("Could not load albums of artist '\(artist.id)': \($0).")
                        self.errorNotifier.notify(Localized("Could not load artist albums."))
                    }
                    self.refreshControl?.endRefreshing()
                })
            }
            if downloadedArtistSongs == nil {
                log.info("Fetching downloaded albums of artist '\(artist.id)'...")
                libraryService.getArtistAlbums(artist.id, onSuccess: {
                    if self.downloadedArtistSongs == nil && self.artist?.id == artist.id {
                        self.downloadedArtistSongs = []
                        for albumSongs in $0.albums {
                            for song in albumSongs.songs {
                                self.downloadedArtistSongs!.insert(song)
                            }
                        }
                        doLoadAlbums()
                    }
                }, onFailure: {
                    if self.downloadedArtistSongs == nil && self.artist?.id == artist.id {
                        if Error.fetchFirstByCodes([Error.CODE_ARTIST_NOT_FOUND], fromArray: $0) != nil {
                            self.downloadedArtistSongs = []
                            doLoadAlbums()
                        } else {
                            self.log.error("Could not fetch downloaded albums of artist '\(artist.id)': \($0).")
                            self.errorNotifier.notify(Localized("Could not fetch downloaded artist albums."))
                        }
                    }
                })
            } else {
                doLoadAlbums()
            }
        } else {
            tableView.reloadData()
        }
    }

    private func shouldSong(song: Song, renderDiscNumberAtAlbumIndex albumIndex: Int) -> Bool {
        var isCellWithDiscNumber = false
        let albumDiscs = albumDiscsToSongs[albumIndex]
        if albumDiscs.count > 1 {
            for (_, songs) in albumDiscs {
                if songs[0].id == song.id {
                    isCellWithDiscNumber = true
                    break
                }
            }
        }
        return isCellWithDiscNumber
    }

    @IBAction
    private func onRefresh() {
        loadAlbums()
    }

}
