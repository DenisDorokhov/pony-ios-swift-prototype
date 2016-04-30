//
// Created by Denis Dorokhov on 30/04/16.
// Copyright (c) 2016 Denis Dorokhov. All rights reserved.
//

import Foundation
import Alamofire
import AlamofireObjectMapper
import XCGLogger
import ObjectMapper

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
            (response: Response<ResponseDto<InstallationDto>, NSError>) in
            self.executeCallback(response, onSuccess, onFailure)
        }
    }

    func authenticate(credentials: CredentialsDto,
                      onSuccess: (AuthenticationDto -> Void)? = nil,
                      onFailure: ([ErrorDto] -> Void)? = nil) -> Request {
        return alamofireManager.request(.POST, buildUrl("/api/authenticate"),
                parameters: Mapper().toJSON(credentials), encoding: .JSON).responseObject {
            (response: Response<ResponseDto<AuthenticationDto>, NSError>) in
            self.executeCallback(response, onSuccess, onFailure)
        }
    }

    func logout(onSuccess onSuccess: (UserDto -> Void)? = nil,
                onFailure: ([ErrorDto] -> Void)? = nil) -> Request {
        return alamofireManager.request(.POST, buildUrl("/api/logout"),
                headers: buildAuthorizationHeaders()).responseObject {
            (response: Response<ResponseDto<UserDto>, NSError>) in
            self.executeCallback(response, onSuccess, onFailure)
        }
    }

    func getCurrentUser(onSuccess onSuccess: (UserDto -> Void)? = nil,
                        onFailure: ([ErrorDto] -> Void)? = nil) -> Request {
        return alamofireManager.request(.GET, buildUrl("/api/currentUser"),
                headers: buildAuthorizationHeaders()).responseObject {
            (response: Response<ResponseDto<UserDto>, NSError>) in
            self.executeCallback(response, onSuccess, onFailure)
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
            (response: Response<ResponseDto<AuthenticationDto>, NSError>) in
            self.executeCallback(response, onSuccess, onFailure)
        }
    }

    private func buildUrl(path: String) -> NSURL {
        return restUrlDao.fetchUrl()!.URLByAppendingPathComponent(path)
    }

    private func buildAuthorizationHeaders() -> [String: String] {
        var headers = [String: String]()
        if let tokenPair = tokenPairDao.fetchTokenPair() {
            headers[HEADER_ACCESS_TOKEN] = tokenPair.accessToken
        }
        return headers
    }

    private func errorToDto(error: NSError) -> ErrorDto {

        if error.domain  == NSURLErrorDomain {
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

    private func executeCallback<T>(response: Response<ResponseDto<T>, NSError>,
                                    _ onSuccess: (T -> Void)? = nil,
                                    _ onFailure: ([ErrorDto] -> Void)? = nil) {
        if response.result.isSuccess {
            let dto = response.result.value!
            if dto.successful ?? false {
                if let data = dto.data {
                    onSuccess?(data)
                } else {
                    log.error("Nil data received.")
                    onFailure?([ErrorDto.createUnexpected()])
                }
            } else {
                if let errors = dto.errors {
                    log.error("Response errors: \(errors)")
                    onFailure?(errors)
                } else {
                    log.error("Nil errors received.")
                    onFailure?([ErrorDto.createUnexpected()])
                }
            }
        } else {
            log.error("Unexpected request error: \(response.result.error!).")
            onFailure?([errorToDto(response.result.error!)])
        }
    }
}
