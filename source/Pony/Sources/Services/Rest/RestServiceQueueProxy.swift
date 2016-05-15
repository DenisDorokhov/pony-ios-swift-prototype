//
// Created by Denis Dorokhov on 14/05/16.
// Copyright (c) 2016 Denis Dorokhov. All rights reserved.
//

import Foundation
import TaskQueue

class RestServiceQueuedProxy: RestService {

    let targetService: RestService

    let imageQueue: TaskQueue = TaskQueue()
    let songQueue: TaskQueue = TaskQueue()

    init(targetService: RestService) {
        self.targetService = targetService

        imageQueue.maximumNumberOfActiveTasks = 10
        songQueue.maximumNumberOfActiveTasks = 5
    }

    func getInstallation(onSuccess onSuccess: (Installation -> Void)?,
                         onFailure: ([Error] -> Void)?) -> RestRequest {
        return self.targetService.getInstallation(onSuccess: onSuccess, onFailure: onFailure)
    }

    func authenticate(credentials: Credentials,
                      onSuccess: (Authentication -> Void)?,
                      onFailure: ([Error] -> Void)?) -> RestRequest {
        return self.targetService.authenticate(credentials, onSuccess: onSuccess, onFailure: onFailure)
    }

    func logout(onSuccess onSuccess: (User -> Void)?,
                onFailure: ([Error] -> Void)?) -> RestRequest {
        return self.targetService.logout(onSuccess: onSuccess, onFailure: onFailure)
    }

    func getCurrentUser(onSuccess onSuccess: (User -> Void)?,
                        onFailure: ([Error] -> Void)?) -> RestRequest {
        return self.targetService.getCurrentUser(onSuccess: onSuccess, onFailure: onFailure)
    }

    func refreshToken(onSuccess onSuccess: (Authentication -> Void)?,
                      onFailure: ([Error] -> Void)?) -> RestRequest {
        return self.targetService.refreshToken(onSuccess: onSuccess, onFailure: onFailure)
    }

    func getArtists(onSuccess onSuccess: ([Artist] -> Void)?,
                    onFailure: ([Error] -> Void)?) -> RestRequest {
        return self.targetService.getArtists(onSuccess: onSuccess, onFailure: onFailure)
    }

    func getArtistAlbums(artistId: Int64, onSuccess: (ArtistAlbums -> Void)?,
                         onFailure: ([Error] -> Void)?) -> RestRequest {
        return self.targetService.getArtistAlbums(artistId, onSuccess: onSuccess, onFailure: onFailure)
    }

    func downloadImage(absoluteUrl: String,
                       onSuccess: (UIImage -> Void)?,
                       onFailure: ([Error] -> Void)?) -> RestRequest {
        let request = RestRequestProxy()
        imageQueue.tasks += {
            _, next in
            if request.cancelled {
                onFailure?([Error.clientRequestCancelled])
                next(nil)
            } else {
                request.targetRequest = self.targetService.downloadImage(absoluteUrl, onSuccess: {
                    onSuccess?($0)
                    next(nil)
                }, onFailure: {
                    onFailure?($0)
                    next(nil)
                })
            }
        }
        imageQueue.run()
        return request
    }

    func downloadSong(absoluteUrl: String, toFile filePath: String,
                      onProgress: (Float -> Void)?,
                      onSuccess: (Void -> Void)?,
                      onFailure: ([Error] -> Void)?) -> RestRequest {
        let request = RestRequestProxy()
        songQueue.tasks += {
            _, next in
            if request.cancelled {
                onFailure?([Error.clientRequestCancelled])
                next(nil)
            } else {
                request.targetRequest = self.targetService.downloadSong(absoluteUrl, toFile: filePath, onProgress: onProgress, onSuccess: {
                    onSuccess?($0)
                    next(nil)
                }, onFailure: {
                    onFailure?($0)
                    next(nil)
                })
            }
        }
        songQueue.run()
        return request
    }

}