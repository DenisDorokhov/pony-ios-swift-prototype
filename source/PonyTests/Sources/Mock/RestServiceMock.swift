//
// Created by Denis Dorokhov on 01/05/16.
// Copyright (c) 2016 Denis Dorokhov. All rights reserved.
//

import Foundation
import UIKit
import Async
import SwiftyTimer

@testable import Pony

class RestServiceMock: RestService {

    var installation: Installation?
    var authentication: Authentication?
    var logoutUser: User?
    var currentUser: User?
    var refreshTokenAuthentication: Authentication?
    var artists: [Artist]?
    var artistAlbums: ArtistAlbums?
    var imagePath: String?
    var songPath: String?

    var didCallGetInstallation: Bool = false
    var didCallAuthenticate: Bool = false
    var didCallLogout: Bool = false
    var didCallCurrentUser: Bool = false
    var didCallRefreshToken: Bool = false
    var didCallGetArtists: Bool = false
    var didCallGetArtistAlbums: Bool = false
    var didCallDownloadImage: Bool = false
    var didCallDownloadSong: Bool = false

    var errors: [Error] = [Error.unexpected]

    func getInstallation(onSuccess onSuccess: (Installation -> Void)?,
                         onFailure: ([Error] -> Void)?) -> RestRequest {
        didCallGetInstallation = true
        let request = RestRequestProxy()
        Async.main {
            if request.cancelled {
                onFailure?([Error.clientRequestCancelled])
            } else {
                if let installation = self.installation {
                    onSuccess?(installation)
                } else {
                    onFailure?(self.errors)
                }
            }
        }
        return request
    }

    func authenticate(credentials: Credentials,
                      onSuccess: (Authentication -> Void)?,
                      onFailure: ([Error] -> Void)?) -> RestRequest {
        didCallAuthenticate = true
        let request = RestRequestProxy()
        Async.main {
            if request.cancelled {
                onFailure?([Error.clientRequestCancelled])
            } else {
                if let authentication = self.authentication {
                    onSuccess?(authentication)
                } else {
                    onFailure?(self.errors)
                }
            }
        }
        return request
    }

    func logout(onSuccess onSuccess: (User -> Void)?,
                onFailure: ([Error] -> Void)?) -> RestRequest {
        didCallLogout = true
        let request = RestRequestProxy()
        Async.main {
            if request.cancelled {
                onFailure?([Error.clientRequestCancelled])
            } else {
                if let logoutUser = self.logoutUser {
                    onSuccess?(logoutUser)
                } else {
                    onFailure?(self.errors)
                }
            }
        }
        return request
    }

    func getCurrentUser(onSuccess onSuccess: (User -> Void)?,
                        onFailure: ([Error] -> Void)?) -> RestRequest {
        didCallCurrentUser = true
        let request = RestRequestProxy()
        Async.main {
            if request.cancelled {
                onFailure?([Error.clientRequestCancelled])
            } else {
                if let currentUser = self.currentUser {
                    onSuccess?(currentUser)
                } else {
                    onFailure?(self.errors)
                }
            }
        }
        return request
    }

    func refreshToken(onSuccess onSuccess: (Authentication -> Void)?,
                      onFailure: ([Error] -> Void)?) -> RestRequest {
        didCallRefreshToken = true
        let request = RestRequestProxy()
        Async.main {
            if request.cancelled {
                onFailure?([Error.clientRequestCancelled])
            } else {
                if let refreshTokenAuthentication = self.refreshTokenAuthentication {
                    onSuccess?(refreshTokenAuthentication)
                } else {
                    onFailure?(self.errors)
                }
            }
        }
        return request
    }

    func getArtists(onSuccess onSuccess: ([Artist] -> Void)?,
                    onFailure: ([Error] -> Void)?) -> RestRequest {
        didCallGetArtists = true
        let request = RestRequestProxy()
        Async.main {
            if request.cancelled {
                onFailure?([Error.clientRequestCancelled])
            } else {
                if let artists = self.artists {
                    onSuccess?(artists)
                } else {
                    onFailure?(self.errors)
                }
            }
        }
        return request
    }

    func getArtistAlbums(artistId: Int64,
                         onSuccess: (ArtistAlbums -> Void)?,
                         onFailure: ([Error] -> Void)?) -> RestRequest {
        didCallGetArtistAlbums = true
        let request = RestRequestProxy()
        Async.main {
            if request.cancelled {
                onFailure?([Error.clientRequestCancelled])
            } else {
                if let artistAlbums = self.artistAlbums {
                    onSuccess?(artistAlbums)
                } else {
                    onFailure?(self.errors)
                }
            }
        }
        return request
    }

    func downloadImage(absoluteUrl: String,
                       onSuccess: (UIImage -> Void)?,
                       onFailure: ([Error] -> Void)?) -> RestRequest {
        didCallDownloadImage = true
        let request = RestRequestProxy()
        Async.main {
            if request.cancelled {
                onFailure?([Error.clientRequestCancelled])
            } else {
                if let imagePath = self.imagePath {
                    onSuccess?(UIImage(data: NSData(contentsOfFile: imagePath)!)!)
                } else {
                    onFailure?(self.errors)
                }
            }
        }
        return request
    }

    func downloadSong(absoluteUrl: String, toFile filePath: String,
                      onProgress: (Float -> Void)?,
                      onSuccess: (Void -> Void)?,
                      onFailure: ([Error] -> Void)?) -> RestRequest {
        didCallDownloadSong = true
        let request = RestRequestProxy()
        NSTimer.after(0.1) {
            if !request.cancelled {
                onProgress?(0.2)
            }
        }
        NSTimer.after(0.2) {
            if !request.cancelled {
                onProgress?(1.0)
            }
            Async.main {
                if request.cancelled {
                    onFailure?([Error.clientRequestCancelled])
                } else {
                    if let songPath = self.songPath {
                        try! NSFileManager.defaultManager().copyItemAtPath(songPath, toPath: filePath)
                        onSuccess?()
                    } else {
                        onFailure?(self.errors)
                    }
                }
            }
        }
        return request
    }
}
