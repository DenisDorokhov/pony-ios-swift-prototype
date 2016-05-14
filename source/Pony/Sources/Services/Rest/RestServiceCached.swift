//
// Created by Denis Dorokhov on 14/05/16.
// Copyright (c) 2016 Denis Dorokhov. All rights reserved.
//

import Foundation
import Haneke
import XCGLogger

class RestServiceCached: RestService {

    private let IMAGE_CACHE_FORMAT = "RestServiceCached.imageCacheFormat"

    private let log = XCGLogger.defaultInstance()

    let targetService: RestService

    let imageCache: Cache<UIImage>

    init(targetService: RestService) {
        self.targetService = targetService

        let imageCacheFormat = Format<UIImage>(name: IMAGE_CACHE_FORMAT,
                diskCapacity: 50 * 1024 * 1024)

        imageCache = Cache<UIImage>(name: "RestServiceCached.imageCache")
        imageCache.addFormat(imageCacheFormat)
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
        imageCache.fetch(key: absoluteUrl, formatName: IMAGE_CACHE_FORMAT, success: {
            image in
            if request.cancelled {
                onFailure?([Error.clientRequestCancelled])
            } else {
                self.log.debug("Cache hit for image '\(absoluteUrl)'.")
                onSuccess?(image)
            }
        }, failure: {
            error in
            if request.cancelled {
                onFailure?([Error.clientRequestCancelled])
            } else {
                self.log.debug("Cache miss for image '\(absoluteUrl)'.")
                request.targetRequest = self.targetService.downloadImage(absoluteUrl, onSuccess: {
                    self.imageCache.set(value: $0, key: absoluteUrl, formatName: self.IMAGE_CACHE_FORMAT)
                    onSuccess?($0)
                }, onFailure: onFailure)
            }
        })
        return request
    }

    func downloadSong(absoluteUrl: String, toFile filePath: String,
                      onProgress: (Float -> Void)?,
                      onSuccess: (Void -> Void)?,
                      onFailure: ([Error] -> Void)?) -> RestRequest {
        return self.targetService.downloadSong(absoluteUrl, toFile: filePath,
                onProgress: onProgress, onSuccess: onSuccess, onFailure: onFailure)
    }
}
