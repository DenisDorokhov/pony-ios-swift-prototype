//
// Created by Denis Dorokhov on 26/04/16.
// Copyright (c) 2016 Denis Dorokhov. All rights reserved.
//

import Foundation
import Alamofire
import XCGLogger

class AlamofireManager: Manager {

    private let log = XCGLogger.defaultInstance()

    var debug: Bool

    init(debug: Bool = false) {

        self.debug = debug

        let config: NSURLSessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration()

        config.HTTPAdditionalHeaders = Manager.defaultHTTPHeaders

        super.init(configuration: config)
    }

    override func request(URLRequest: URLRequestConvertible) -> Request {
        let request = super.request(URLRequest)
        if debug {
            // TODO: more readable request dump
            log.debug("RestManager request:\n\(request.debugDescription)\n")
            request.response {
                request, response, data, error in
                self.log.debug("RestManager response:\n\(self.dumpResponse(request, response, data, error))\n")
            }
        }
        return request
    }

    private func dumpResponse(request: NSURLRequest?, _ response: NSHTTPURLResponse?,
                              _ data: NSData?, _ error: NSError?) -> String {

        var output: [String] = []

        output.append(request != nil ? "[Request]: \(request!)" : "[Request]: nil")
        output.append(response != nil ? "[Response]: \(response!)" : "[Response]: nil")
        output.append("[Data]: \(data?.length ?? 0) bytes")
        output.append(error != nil ? "[Error]: \(error!)" : "[Error]: nil")

        if data != nil {
            do {
                let json = try NSJSONSerialization.JSONObjectWithData(data!, options: .MutableContainers)
                let pretty = try NSJSONSerialization.dataWithJSONObject(json, options: .PrettyPrinted)
                if let string = NSString(data: pretty, encoding: NSUTF8StringEncoding) {
                    output.append("[JSON]: \(string)")
                }
            } catch {
                if let string = NSString(data: data!, encoding: NSUTF8StringEncoding) {
                    output.append("[Output]: \(string)")
                } else {
                    output.append("[Output]: \(data)")
                }
            }
        }

        return output.joinWithSeparator("\n")
    }
}
