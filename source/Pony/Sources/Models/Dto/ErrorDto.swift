//
// Created by Denis Dorokhov on 29/04/16.
// Copyright (c) 2016 Denis Dorokhov. All rights reserved.
//

import Foundation
import ObjectMapper

class ErrorDto: Mappable, CustomStringConvertible {

    static let CODE_CLIENT_REQUEST_FAILED = "errorClientRequestFailed"
    static let CODE_CLIENT_REQUEST_TIMEOUT = "errorClientRequestTimeout"
    static let CODE_CLIENT_REQUEST_CANCELLED = "errorClientRequestCancelled"
    static let CODE_CLIENT_OFFLINE = "errorClientOffline"
    static let CODE_INVALID_CONTENT_TYPE = "errorInvalidContentType"
    static let CODE_INVALID_REQUEST = "errorInvalidRequest"
    static let CODE_ACCESS_DENIED = "errorAccessDenied"
    static let CODE_VALIDATION = "errorValidation"
    static let CODE_UNEXPECTED = "errorUnexpected"
    static let CODE_INVALID_CREDENTIALS = "errorInvalidCredentials"
    static let CODE_INVALID_PASSWORD = "errorInvalidPassword"
    static let CODE_SCAN_JOB_NOT_FOUND = "errorScanJobNotFound"
    static let CODE_SCAN_RESULT_NOT_FOUND = "errorScanResultNotFound"
    static let CODE_ARTIST_NOT_FOUND = "errorArtistNotFound"
    static let CODE_SONG_NOT_FOUND = "errorSongNotFound"
    static let CODE_USER_NOT_FOUND = "errorUserNotFound"
    static let CODE_ARTWORK_UPLOAD_NOT_FOUND = "errorArtworkUploadNotFound"
    static let CODE_ARTWORK_UPLOAD_FORMAT = "errorArtworkUploadFormat"
    static let CODE_LIBRARY_NOT_DEFINED = "errorLibraryNotDefined"
    static let CODE_MAX_UPLOAD_SIZE_EXCEEDED = "errorMaxUploadSizeExceeded"
    static let CODE_USER_SELF_DELETION = "errorUserSelfDeletion"
    static let CODE_USER_SELF_ROLE_MODIFICATION = "errorUserSelfRoleModification"
    static let CODE_PAGE_NUMBER_INVALID = "errorPageNumberInvalid"
    static let CODE_PAGE_SIZE_INVALID = "errorPageSizeInvalid"
    static let CODE_SONGS_COUNT_INVALID = "errorSongsCountInvalid"

    var field: String?
    var code: String?
    var text: String?

    var arguments: [String]?

    init(code: String, text: String, arguments: [String]? = nil, field: String? = nil) {
        self.field = field
        self.code = code
        self.text = text
        self.arguments = arguments
    }

    var description: String {
        get {
            return "ErrorDto{" +
                    "field=\(field)" +
                    ", code=\(code)" +
                    ", text=\(text)" +
                    ", arguments=\(arguments)" +
                    "}"
        }
    }

    class func fetchAllByCodes(codes: [String], fromArray errors: [ErrorDto]) -> [ErrorDto] {
        var result: [ErrorDto] = []
        for error in errors {
            for code in codes {
                if error.code == code || error.code?.hasPrefix("\(code).") ?? false {
                    result.append(error)
                }
            }
        }
        return result
    }

    class func fetchFirstByCodes(codes: [String], fromArray errors: [ErrorDto]) -> ErrorDto? {
        return fetchAllByCodes(codes, fromArray: errors).first
    }

    class func createClientOffline() -> ErrorDto {
        return ErrorDto(code: CODE_CLIENT_OFFLINE, text: "Could not make server request. Are you online?")
    }

    class func createClientRequestTimeout() -> ErrorDto {
        return ErrorDto(code: CODE_CLIENT_REQUEST_TIMEOUT, text: "Client request timed out.")
    }

    class func createClientRequestCancelled() -> ErrorDto {
        return ErrorDto(code: CODE_CLIENT_REQUEST_CANCELLED, text: "Client request has been cancelled.")
    }

    class func createAccessDenied() -> ErrorDto {
        return ErrorDto(code: CODE_ACCESS_DENIED, text: "Access denied.")
    }

    class func createUnexpected() -> ErrorDto {
        return ErrorDto(code: CODE_UNEXPECTED, text: "Unexpected error occurred.")
    }

    required init?(_ map: Map) {}

    func mapping(map: Map) {
        field <- map["field"]
        code <- map["code"]
        text <- map["text"]
        arguments <- map["arguments"]
    }
}
