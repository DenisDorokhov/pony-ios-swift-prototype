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

class RestService {

    private let HEADER_ACCESS_TOKEN = "X-Pony-Access-Token"
    private let HEADER_REFRESH_TOKEN = "X-Pony-Refresh-Token"

    private let log = XCGLogger.defaultInstance()

    var alamofireManager: Manager!
    var tokenPairDao: TokenPairDao!
    var restUrlDao: RestUrlDao!

    func getInstallation(onSuccess onSuccess: (InstallationDto -> Void)? = nil,
                         onFailure: ([ErrorDto] -> Void)? = nil) -> Request {
        return alamofireManager.request(.GET, buildUrl("/api/installation")).responseObject {
            (response: Response<ObjectResponseDto<InstallationDto>, NSError>) in
            self.executeObjectCallback(response, onSuccess, onFailure)
        }
    }

    func authenticate(credentials: CredentialsDto,
                      onSuccess: (AuthenticationDto -> Void)? = nil,
                      onFailure: ([ErrorDto] -> Void)? = nil) -> Request {
        return alamofireManager.request(.POST, buildUrl("/api/authenticate"),
                parameters: Mapper().toJSON(credentials), encoding: .JSON).responseObject {
            (response: Response<ObjectResponseDto<AuthenticationDto>, NSError>) in
            self.executeObjectCallback(response, onSuccess, onFailure)
        }
    }

    func logout(onSuccess onSuccess: (UserDto -> Void)? = nil,
                onFailure: ([ErrorDto] -> Void)? = nil) -> Request {
        return alamofireManager.request(.POST, buildUrl("/api/logout"),
                headers: buildAuthorizationHeaders()).responseObject {
            (response: Response<ObjectResponseDto<UserDto>, NSError>) in
            self.executeObjectCallback(response, onSuccess, onFailure)
        }
    }

    func getCurrentUser(onSuccess onSuccess: (UserDto -> Void)? = nil,
                        onFailure: ([ErrorDto] -> Void)? = nil) -> Request {
        return alamofireManager.request(.GET, buildUrl("/api/currentUser"),
                headers: buildAuthorizationHeaders()).responseObject {
            (response: Response<ObjectResponseDto<UserDto>, NSError>) in
            self.executeObjectCallback(response, onSuccess, onFailure)
        }
    }

    func refreshToken(onSuccess onSuccess: (AuthenticationDto -> Void)? = nil,
                      onFailure: ([ErrorDto] -> Void)? = nil) -> Request {

        var headers = [String: String]()
        if let tokenPair = tokenPairDao.fetchTokenPair() {
            headers[HEADER_REFRESH_TOKEN] = tokenPair.refreshToken
        }

        return alamofireManager.request(.POST, buildUrl("/api/refreshToken"),
                headers: headers).responseObject {
            (response: Response<ObjectResponseDto<AuthenticationDto>, NSError>) in
            self.executeObjectCallback(response, onSuccess, onFailure)
        }
    }

    func getArtists(onSuccess onSuccess: ([ArtistDto] -> Void)? = nil,
                    onFailure: ([ErrorDto] -> Void)? = nil) -> Request {
        return alamofireManager.request(.GET, buildUrl("/api/artists"),
                headers: buildAuthorizationHeaders()).responseObject {
            (response: Response<ArrayResponseDto<ArtistDto>, NSError>) in
            self.executeArrayCallback(response, onSuccess, onFailure)
        }
    }

    func getArtistAlbums(artistId: Int64,
                         onSuccess: (ArtistAlbumsDto -> Void)? = nil,
                         onFailure: ([ErrorDto] -> Void)? = nil) -> Request {
        return alamofireManager.request(.GET, buildUrl("/api/artistAlbums/\(artistId)"),
                headers: buildAuthorizationHeaders()).responseObject {
            (response: Response<ObjectResponseDto<ArtistAlbumsDto>, NSError>) in
            self.executeObjectCallback(response, onSuccess, onFailure)
        }
    }

    func downloadImage(absoluteUrl: String,
                       onSuccess: (UIImage -> Void)? = nil,
                       onFailure: ([ErrorDto] -> Void)? = nil) -> Request {
        return alamofireManager.request(.GET, absoluteUrl,
                headers: buildAuthorizationHeaders()).responseImage {
            response in
            if response.result.isSuccess {
                onSuccess?(response.result.value!)
            } else {
                self.log.error("Image request error: \(response.result.error!).")
                onFailure?([self.errorToDto(response.result.error!)])
            }
        }
    }

    func downloadSong(absoluteUrl: String, toFile filePath: String,
                      onProgress: (Float -> Void)? = nil,
                      onSuccess: (Void -> Void)? = nil,
                      onFailure: ([ErrorDto] -> Void)? = nil) -> Request {

        return alamofireManager.download(.GET, absoluteUrl, headers: buildAuthorizationHeaders(), destination: {
            temporaryURL, response in
            return NSURL(fileURLWithPath: filePath)
        }).progress {
            bytesRead, totalBytesRead, totalBytesExpectedToRead in
            if let onProgress = onProgress {
                dispatch_async(dispatch_get_main_queue()) {
                    onProgress(Float(Double(totalBytesRead) / Double(totalBytesExpectedToRead)))
                }
            }
        }.response {
            _, _, _, error in
            if let error = error {
                self.log.error("Song request error: \(error).")
                onFailure?([self.errorToDto(error)])
            } else {
                onSuccess?()
            }
        }
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

    private func errorToDto(error: NSError) -> ErrorDto {

        if error.domain == NSURLErrorDomain {
            if error.code == NSURLErrorNotConnectedToInternet {
                return ErrorDto.createClientOffline()
            } else if error.code == NSURLErrorTimedOut {
                return ErrorDto.createClientRequestTimeout()
            } else if error.code == NSURLErrorCancelled {
                return ErrorDto.createClientRequestCancelled()
            }
        }

        return ErrorDto(code: ErrorDto.CODE_CLIENT_REQUEST_FAILED, text: "An error occurred when making server request.")
    }

    private func executeObjectCallback<T>(response: Response<ObjectResponseDto<T>, NSError>,
                                          _ onSuccess: (T -> Void)? = nil,
                                          _ onFailure: ([ErrorDto] -> Void)? = nil) {
        if response.result.isSuccess {
            let dto = response.result.value!
            if dto.successful ?? false {
                if let data = dto.data {
                    onSuccess?(data)
                } else {
                    log.error("API returned nil data.")
                    onFailure?([ErrorDto.createUnexpected()])
                }
            } else {
                if let errors = dto.errors {
                    log.error("API response errors: \(errors)")
                    onFailure?(errors)
                } else {
                    log.error("API returned nil errors.")
                    onFailure?([ErrorDto.createUnexpected()])
                }
            }
        } else {
            log.error("API request error: \(response.result.error!).")
            onFailure?([errorToDto(response.result.error!)])
        }
    }

    private func executeArrayCallback<T>(response: Response<ArrayResponseDto<T>, NSError>,
                                         _ onSuccess: ([T] -> Void)? = nil,
                                         _ onFailure: ([ErrorDto] -> Void)? = nil) {
        if response.result.isSuccess {
            let dto = response.result.value!
            if dto.successful ?? false {
                if let data = dto.data {
                    onSuccess?(data)
                } else {
                    log.error("API returned nil data.")
                    onFailure?([ErrorDto.createUnexpected()])
                }
            } else {
                if let errors = dto.errors {
                    log.error("API response errors: \(errors)")
                    onFailure?(errors)
                } else {
                    log.error("API returned nil errors.")
                    onFailure?([ErrorDto.createUnexpected()])
                }
            }
        } else {
            log.error("API request error: \(response.result.error!).")
            onFailure?([errorToDto(response.result.error!)])
        }
    }
}
