//
// Created by Denis Dorokhov on 12/05/16.
// Copyright (c) 2016 Denis Dorokhov. All rights reserved.
//

import UIKit
import XCGLogger
import Localize_Swift

class CloudArtistsController: UITableViewController, AuthServiceDelegate {

    private let log = XCGLogger.defaultInstance()

    var restService: RestService!
    var authService: AuthService!
    var errorNotifier: ErrorNotifier!

    private var artists: [Artist]?
    private var selectedArtist: Artist?

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if artists?.count == nil {
            loadArtists()
        }
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        authService.addDelegate(self)
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        authService.removeDelegate(self)
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        super.prepareForSegue(segue, sender: sender)
        if segue.identifier == "cloudArtistsToCloudAlbums" {
            let albumsController = segue.destinationViewController as! CloudAlbumsController
            albumsController.artist = selectedArtist
        }
    }

    // MARK: AuthServiceDelegate

    func authService(authService: AuthService, didAuthenticateUser user: User) {
        // Do nothing.
    }

    func authService(authService: AuthService, didUpdateUser user: User) {
        // Do nothing.
    }

    func authService(authService: AuthService, didLogoutUser user: User) {
        performSegueWithIdentifier("cloudBootstrapFromCloudArtists", sender: self)
    }

    // MARK: UITableViewDataSource

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return artists?.count ?? 0
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let artistCell = tableView.dequeueReusableCellWithIdentifier("artistCell") as! ArtistCell
        artistCell.artist = artists?[indexPath.row]
        return artistCell
    }

    // MARK: UITableViewDelegate

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        selectedArtist = artists?[indexPath.row]
        performSegueWithIdentifier("cloudArtistsToCloudAlbums", sender: self)
    }

    // MARK: Private

    private func loadArtists() {
        log.info("Loading artists...")
        restService.getArtists(onSuccess: {
            self.artists = $0
            self.log.info("\($0.count) artists loaded.")
            self.refreshControl?.endRefreshing()
            self.tableView.reloadData()
        }, onFailure: {
            if Error.fetchFirstByCodes([Error.CODE_CLIENT_OFFLINE], fromArray: $0) == nil {
                self.log.error("Could not load artists: \($0).")
                self.errorNotifier.notify(Localized("Could not load artists."))
            }
            self.refreshControl?.endRefreshing()
        })
    }

    @IBAction
    private func onLogoutButtonTap() {
        authService.logout()
    }

    @IBAction
    private func onRefresh() {
        loadArtists()
    }

}
