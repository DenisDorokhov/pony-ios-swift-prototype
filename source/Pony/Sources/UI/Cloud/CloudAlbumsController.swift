//
// Created by Denis Dorokhov on 12/05/16.
// Copyright (c) 2016 Denis Dorokhov. All rights reserved.
//

import UIKit
import Localize_Swift
import XCGLogger

class CloudAlbumsController: UITableViewController {

    private let log = XCGLogger.defaultInstance()

    var restService: RestService!
    var errorNotifier: ErrorNotifier!
    var libraryService: LibraryService!

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

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView()
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
        return songCell
    }

    // MARK: UITableViewDelegate

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        // TODO: start download or playback
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

            let artistToLoad = artist
            log.info("Loading albums of artist '\(artist.id)'...")
            currentRequest = restService.getArtistAlbums(artist.id, onSuccess: {
                self.currentRequest = nil
                self.artistAlbums = $0
                self.refreshControl?.endRefreshing()
                self.tableView.reloadData()
                self.log.info("\($0.albums.count) albums of artist '\($0.artist.id)' loaded.")
            }, onFailure: {
                if Error.fetchFirstByCodes([Error.CODE_CLIENT_REQUEST_CANCELLED], fromArray: $0) != nil {
                    self.log.debug("Cancelled loading albums of artist '\(artistToLoad.id)'.")
                } else {
                    self.currentRequest = nil
                    self.log.error("Could not load albums of artist '\(artistToLoad.id)': \($0).")
                    self.errorNotifier.notify("Could not load artist albums")
                }
                self.refreshControl?.endRefreshing()
            })

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
