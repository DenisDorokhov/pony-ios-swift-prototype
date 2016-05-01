//
// Created by Denis Dorokhov on 01/05/16.
// Copyright (c) 2016 Denis Dorokhov. All rights reserved.
//

import Foundation
import UIKit

@testable import Pony

class RestRequestMock: RestRequest {
    func cancel() {}
}

class RestServiceMock: RestService {

    var installation: InstallationDto?
    var authentication: AuthenticationDto?
    var logoutUser: UserDto?
    var currentUser: UserDto?
    var refreshTokenAuthentication: AuthenticationDto?
    var artists: [ArtistDto]?
    var artistAlbums: ArtistAlbumsDto?
    var image: UIImage?
    var song: NSData?

    var errors: [ErrorDto] = [ErrorDto.unexpected]

    func getInstallation(onSuccess onSuccess: (InstallationDto -> Void)?,
                         onFailure: ([ErrorDto] -> Void)?) -> RestRequest {
        dispatch_async(dispatch_get_main_queue()) {
            if let installation = self.installation {
                onSuccess?(installation)
            } else {
                onFailure?(self.errors)
            }
        }
        return RestRequestMock()
    }

    func authenticate(credentials: CredentialsDto,
                      onSuccess: (AuthenticationDto -> Void)?,
                      onFailure: ([ErrorDto] -> Void)?) -> RestRequest {
        dispatch_async(dispatch_get_main_queue()) {
            if let authentication = self.authentication {
                onSuccess?(authentication)
            } else {
                onFailure?(self.errors)
            }
        }
        return RestRequestMock()
    }

    func logout(onSuccess onSuccess: (UserDto -> Void)?,
                onFailure: ([ErrorDto] -> Void)?) -> RestRequest {
        dispatch_async(dispatch_get_main_queue()) {
            if let logoutUser = self.logoutUser {
                onSuccess?(logoutUser)
            } else {
                onFailure?(self.errors)
            }
        }
        return RestRequestMock()
    }

    func getCurrentUser(onSuccess onSuccess: (UserDto -> Void)?,
                        onFailure: ([ErrorDto] -> Void)?) -> RestRequest {
        dispatch_async(dispatch_get_main_queue()) {
            if let currentUser = self.currentUser {
                onSuccess?(currentUser)
            } else {
                onFailure?(self.errors)
            }
        }
        return RestRequestMock()
    }

    func refreshToken(onSuccess onSuccess: (AuthenticationDto -> Void)?,
                      onFailure: ([ErrorDto] -> Void)?) -> RestRequest {
        dispatch_async(dispatch_get_main_queue()) {
            if let refreshTokenAuthentication = self.refreshTokenAuthentication {
                onSuccess?(refreshTokenAuthentication)
            } else {
                onFailure?(self.errors)
            }
        }
        return RestRequestMock()
    }

    func getArtists(onSuccess onSuccess: ([ArtistDto] -> Void)?,
                    onFailure: ([ErrorDto] -> Void)?) -> RestRequest {
        dispatch_async(dispatch_get_main_queue()) {
            if let artists = self.artists {
                onSuccess?(artists)
            } else {
                onFailure?(self.errors)
            }
        }
        return RestRequestMock()
    }

    func getArtistAlbums(artistId: Int64,
                         onSuccess: (ArtistAlbumsDto -> Void)?,
                         onFailure: ([ErrorDto] -> Void)?) -> RestRequest {
        dispatch_async(dispatch_get_main_queue()) {
            if let artistAlbums = self.artistAlbums {
                onSuccess?(artistAlbums)
            } else {
                onFailure?(self.errors)
            }
        }
        return RestRequestMock()
    }

    func downloadImage(absoluteUrl: String,
                       onSuccess: (UIImage -> Void)?,
                       onFailure: ([ErrorDto] -> Void)?) -> RestRequest {
        dispatch_async(dispatch_get_main_queue()) {
            if let image = self.image {
                onSuccess?(image)
            } else {
                onFailure?(self.errors)
            }
        }
        return RestRequestMock()
    }

    func downloadSong(absoluteUrl: String, toFile filePath: String,
                      onProgress: (Float -> Void)?,
                      onSuccess: (Void -> Void)?,
                      onFailure: ([ErrorDto] -> Void)?) -> RestRequest {
        dispatch_async(dispatch_get_main_queue()) {
            if let song = self.song {
                song.writeToFile(filePath, atomically: true)
                onSuccess?()
            } else {
                onFailure?(self.errors)
            }
        }
        return RestRequestMock()
    }
}
