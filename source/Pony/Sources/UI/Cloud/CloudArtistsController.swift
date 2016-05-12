//
// Created by Denis Dorokhov on 12/05/16.
// Copyright (c) 2016 Denis Dorokhov. All rights reserved.
//

import UIKit

class CloudArtistsController: UIViewController, AuthServiceDelegate {

    var restService: RestService!
    var authService: AuthService!
    var errorNotifier: ErrorNotifier!

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        authService.addDelegate(self)
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        authService.removeDelegate(self)
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

    // MARK: Private

    @IBAction
    private func onLogoutButtonTap() {
        authService.logout()
    }

}
