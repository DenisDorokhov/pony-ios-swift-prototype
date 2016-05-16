//
// Created by Denis Dorokhov on 14/05/16.
// Copyright (c) 2016 Denis Dorokhov. All rights reserved.
//

import UIKit

class RestServiceQueuedProxy: RestService {

    private let targetService: RestService
    private let imageChain = TaskChain(maxConcurrentTasks: 10)
    private let songChain = TaskChain(maxConcurrentTasks: 3)

    init(targetService: RestService) {
        self.targetService = targetService
    }

    func getInstallation(onSuccess onSuccess: (Installation -> Void)?,
                         onFailure: ([Error] -> Void)?) -> RestRequest {
        return targetService.getInstallation(onSuccess: onSuccess, onFailure: onFailure)
    }

    func authenticate(credentials: Credentials,
                      onSuccess: (Authentication -> Void)?,
                      onFailure: ([Error] -> Void)?) -> RestRequest {
        return targetService.authenticate(credentials, onSuccess: onSuccess, onFailure: onFailure)
    }

    func logout(onSuccess onSuccess: (User -> Void)?,
                onFailure: ([Error] -> Void)?) -> RestRequest {
        return targetService.logout(onSuccess: onSuccess, onFailure: onFailure)
    }

    func getCurrentUser(onSuccess onSuccess: (User -> Void)?,
                        onFailure: ([Error] -> Void)?) -> RestRequest {
        return targetService.getCurrentUser(onSuccess: onSuccess, onFailure: onFailure)
    }

    func refreshToken(onSuccess onSuccess: (Authentication -> Void)?,
                      onFailure: ([Error] -> Void)?) -> RestRequest {
        return targetService.refreshToken(onSuccess: onSuccess, onFailure: onFailure)
    }

    func getArtists(onSuccess onSuccess: ([Artist] -> Void)?,
                    onFailure: ([Error] -> Void)?) -> RestRequest {
        return targetService.getArtists(onSuccess: onSuccess, onFailure: onFailure)
    }

    func getArtistAlbums(artistId: Int64, onSuccess: (ArtistAlbums -> Void)?,
                         onFailure: ([Error] -> Void)?) -> RestRequest {
        return targetService.getArtistAlbums(artistId, onSuccess: onSuccess, onFailure: onFailure)
    }

    func downloadImage(absoluteUrl: String,
                       onSuccess: (UIImage -> Void)?,
                       onFailure: ([Error] -> Void)?) -> RestRequest {
        let request = RestRequestProxy()
        imageChain.addTask {
            next, cancel in
            if request.cancelled {
                onFailure?([Error.clientRequestCancelled])
                next()
            } else {
                request.targetRequest = self.targetService.downloadImage(absoluteUrl, onSuccess: {
                    onSuccess?($0)
                    next()
                }, onFailure: {
                    onFailure?($0)
                    next()
                })
            }
        }
        return request
    }

    func downloadSong(absoluteUrl: String, toFile filePath: String,
                      onProgress: (Float -> Void)?,
                      onSuccess: (Void -> Void)?,
                      onFailure: ([Error] -> Void)?) -> RestRequest {
        let request = RestRequestProxy()
        songChain.addTask {
            next, cancel in
            if request.cancelled {
                onFailure?([Error.clientRequestCancelled])
                next()
            } else {
                request.targetRequest = self.targetService.downloadSong(absoluteUrl, toFile: filePath, onProgress: onProgress, onSuccess: {
                    onSuccess?($0)
                    next()
                }, onFailure: {
                    onFailure?($0)
                    next()
                })
            }
        }
        return request
    }

}
