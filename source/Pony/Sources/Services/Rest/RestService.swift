//
// Created by Denis Dorokhov on 30/04/16.
// Copyright (c) 2016 Denis Dorokhov. All rights reserved.
//

import Foundation
import Alamofire
import AlamofireObjectMapper
import XCGLogger
import ObjectMapper
import AlamofireImage
import Async

protocol RestRequest: class {
    func cancel()
}

protocol RestService: class {
    func getInstallation(onSuccess onSuccess: (Installation -> Void)?,
                         onFailure: ([Error] -> Void)?) -> RestRequest
    func authenticate(credentials: Credentials,
                      onSuccess: (Authentication -> Void)?,
                      onFailure: ([Error] -> Void)?) -> RestRequest
    func logout(onSuccess onSuccess: (User -> Void)?,
                onFailure: ([Error] -> Void)?) -> RestRequest
    func getCurrentUser(onSuccess onSuccess: (User -> Void)?,
                        onFailure: ([Error] -> Void)?) -> RestRequest
    func refreshToken(onSuccess onSuccess: (Authentication -> Void)?,
                      onFailure: ([Error] -> Void)?) -> RestRequest
    func getArtists(onSuccess onSuccess: ([Artist] -> Void)?,
                    onFailure: ([Error] -> Void)?) -> RestRequest
    func getArtistAlbums(artistId: Int64,
                         onSuccess: (ArtistAlbums -> Void)?,
                         onFailure: ([Error] -> Void)?) -> RestRequest
    func downloadImage(absoluteUrl: String,
                       onSuccess: (UIImage -> Void)?,
                       onFailure: ([Error] -> Void)?) -> RestRequest
    func downloadSong(absoluteUrl: String, toFile filePath: String,
                      onProgress: (Float -> Void)?,
                      onSuccess: (Void -> Void)?,
                      onFailure: ([Error] -> Void)?) -> RestRequest
}

class RestRequestAlamofire: RestRequest {

    let request: Request

    private let onCancel: (Void -> Void)?

    init(_ request: Request, onCancel: (Void -> Void)? = nil) {
        self.request = request
        self.onCancel = onCancel
    }

    func cancel() {
        request.cancel()
        onCancel?()
    }
}

class RestRequestProxy: RestRequest {

    private(set) var cancelled = false

    var targetRequest: RestRequest? {
        willSet {
            assert(!cancelled)
        }
    }

    func cancel() {
        cancelled = true
        targetRequest?.cancel()
    }
}

class RestServiceImpl: RestService {

    private let HEADER_ACCESS_TOKEN = "X-Pony-Access-Token"
    private let HEADER_REFRESH_TOKEN = "X-Pony-Refresh-Token"

    private let log = XCGLogger.defaultInstance()

    var alamofireManager: Manager!
    var tokenPairDao: TokenPairDao!
    var restUrlDao: RestUrlDao!

    init() {
        Request.addAcceptableImageContentTypes(["image/jpg"])
    }

    func getInstallation(onSuccess onSuccess: (Installation -> Void)? = nil,
                         onFailure: ([Error] -> Void)? = nil) -> RestRequest {
        return RestRequestAlamofire(alamofireManager.request(.GET, buildUrl("/api/installation")).responseObject {
            (response: Alamofire.Response<ObjectResponse<Installation>, NSError>) in
            self.executeObjectCallback(response, onSuccess, onFailure)
        })
    }

    func authenticate(credentials: Credentials,
                      onSuccess: (Authentication -> Void)? = nil,
                      onFailure: ([Error] -> Void)? = nil) -> RestRequest {
        return RestRequestAlamofire(alamofireManager.request(.POST, buildUrl("/api/authenticate"),
                parameters: Mapper().toJSON(credentials), encoding: .JSON).responseObject {
            (response: Alamofire.Response<ObjectResponse<Authentication>, NSError>) in
            self.executeObjectCallback(response, onSuccess, onFailure)
        })
    }

    func logout(onSuccess onSuccess: (User -> Void)? = nil,
                onFailure: ([Error] -> Void)? = nil) -> RestRequest {
        return RestRequestAlamofire(alamofireManager.request(.POST, buildUrl("/api/logout"),
                headers: buildAuthorizationHeaders()).responseObject {
            (response: Alamofire.Response<ObjectResponse<User>, NSError>) in
            self.executeObjectCallback(response, onSuccess, onFailure)
        })
    }

    func getCurrentUser(onSuccess onSuccess: (User -> Void)? = nil,
                        onFailure: ([Error] -> Void)? = nil) -> RestRequest {
        return RestRequestAlamofire(alamofireManager.request(.GET, buildUrl("/api/currentUser"),
                headers: buildAuthorizationHeaders()).responseObject {
            (response: Alamofire.Response<ObjectResponse<User>, NSError>) in
            self.executeObjectCallback(response, onSuccess, onFailure)
        })
    }

    func refreshToken(onSuccess onSuccess: (Authentication -> Void)? = nil,
                      onFailure: ([Error] -> Void)? = nil) -> RestRequest {

        var headers = [String: String]()
        if let tokenPair = tokenPairDao.fetchTokenPair() {
            headers[HEADER_REFRESH_TOKEN] = tokenPair.refreshToken
        }

        return RestRequestAlamofire(alamofireManager.request(.POST, buildUrl("/api/refreshToken"),
                headers: headers).responseObject {
            (response: Alamofire.Response<ObjectResponse<Authentication>, NSError>) in
            self.executeObjectCallback(response, onSuccess, onFailure)
        })
    }

    func getArtists(onSuccess onSuccess: ([Artist] -> Void)? = nil,
                    onFailure: ([Error] -> Void)? = nil) -> RestRequest {
        return RestRequestAlamofire(alamofireManager.request(.GET, buildUrl("/api/artists"),
                headers: buildAuthorizationHeaders()).responseObject {
            (response: Alamofire.Response<ArrayResponse<Artist>, NSError>) in
            self.executeArrayCallback(response, onSuccess, onFailure)
        })
    }

    func getArtistAlbums(artistId: Int64,
                         onSuccess: (ArtistAlbums -> Void)? = nil,
                         onFailure: ([Error] -> Void)? = nil) -> RestRequest {
        return RestRequestAlamofire(alamofireManager.request(.GET, buildUrl("/api/artistAlbums/\(artistId)"),
                headers: buildAuthorizationHeaders()).responseObject {
            (response: Alamofire.Response<ObjectResponse<ArtistAlbums>, NSError>) in
            self.executeObjectCallback(response, onSuccess, onFailure)
        })
    }

    func downloadImage(absoluteUrl: String,
                       onSuccess: (UIImage -> Void)? = nil,
                       onFailure: ([Error] -> Void)? = nil) -> RestRequest {
        return RestRequestAlamofire(alamofireManager.request(.GET, absoluteUrl,
                headers: buildAuthorizationHeaders()).responseImage {
            response in
            if response.result.isSuccess {
                onSuccess?(response.result.value!)
            } else {
                let convertedError = self.buildError(response.result.error!)
                if convertedError.code != Error.CODE_CLIENT_REQUEST_CANCELLED {
                    self.log.error("Image request error: \(response.result.error!).")
                }
                onFailure?([convertedError])
            }
        })
    }

    func downloadSong(absoluteUrl: String, toFile filePath: String,
                      onProgress: (Float -> Void)? = nil,
                      onSuccess: (Void -> Void)? = nil,
                      onFailure: ([Error] -> Void)? = nil) -> RestRequest {
        var cancelled = false
        let onCancel = {
            cancelled = true
        }
        return RestRequestAlamofire(alamofireManager.download(.GET, absoluteUrl, headers: buildAuthorizationHeaders(), destination: {
            temporaryURL, response in
            return NSURL(fileURLWithPath: filePath)
        }).progress {
            bytesRead, totalBytesRead, totalBytesExpectedToRead in
            if let onProgress = onProgress {
                Async.main {
                    // Avoid calling progress after request is cancelled.
                    if !cancelled {
                        onProgress(Float(Double(totalBytesRead) / Double(totalBytesExpectedToRead)))
                    }
                }
            }
        }.response {
            _, _, _, error in
            if let error = error {
                let convertedError = self.buildError(error)
                if convertedError.code != Error.CODE_CLIENT_REQUEST_CANCELLED {
                    self.log.error("Song request error: \(error).")
                }
                onFailure?([convertedError])
            } else {
                onSuccess?()
            }
        }, onCancel: onCancel)
    }

    private func buildUrl(path: String) -> NSURL {
        return restUrlDao.fetchUrl()!.URLByAppendingPathComponent(path)
    }

    private func buildAuthorizationHeaders() -> [String:String] {
        var headers = [String: String]()
        if let tokenPair = tokenPairDao.fetchTokenPair() {
            headers[HEADER_ACCESS_TOKEN] = tokenPair.accessToken
        }
        return headers
    }

    private func buildError(error: NSError) -> Error {

        if error.domain == NSURLErrorDomain {
            if error.code == NSURLErrorNotConnectedToInternet {
                return Error.clientOffline
            } else if error.code == NSURLErrorTimedOut {
                return Error.clientRequestTimeout
            } else if error.code == NSURLErrorCancelled {
                return Error.clientRequestCancelled
            }
        }

        return Error(code: Error.CODE_CLIENT_REQUEST_FAILED, text: "An error occurred when making server request.")
    }

    private func executeObjectCallback<T>(response: Alamofire.Response<ObjectResponse<T>, NSError>,
                                          _ onSuccess: (T -> Void)?,
                                          _ onFailure: ([Error] -> Void)?) {
        executeResponseCallback(response, {
            if let data = $0.data {
                onSuccess?(data)
            } else {
                self.log.error("API returned nil data object.")
                onFailure?([Error.unexpected])
            }
        }, onFailure)
    }

    private func executeArrayCallback<T>(response: Alamofire.Response<ArrayResponse<T>, NSError>,
                                         _ onSuccess: ([T] -> Void)?,
                                         _ onFailure: ([Error] -> Void)?) {
        executeResponseCallback(response, {
            onSuccess?($0.data!)
        }, onFailure)
    }

    private func executeResponseCallback<T: Response>(response: Alamofire.Response<T, NSError>,
                                                     _ onSuccess: (T -> Void)?,
                                                     _ onFailure: ([Error] -> Void)?) {
        if response.result.isSuccess {
            let responseValue = response.result.value!
            if responseValue.successful ?? false {
                onSuccess?(responseValue)
            } else {
                log.error("API response errors: \(responseValue.errors)")
                onFailure?(responseValue.errors)
            }
        } else {
            let convertedError = self.buildError(response.result.error!)
            if convertedError.code != Error.CODE_CLIENT_REQUEST_CANCELLED {
                log.error("API request error: \(response.result.error!).")
            }
            onFailure?([convertedError])
        }
    }
}
