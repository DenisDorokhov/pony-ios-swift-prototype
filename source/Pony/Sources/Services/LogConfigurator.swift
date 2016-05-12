//
// Created by Denis Dorokhov on 12/05/16.
// Copyright (c) 2016 Denis Dorokhov. All rights reserved.
//

import Foundation
import XCGLogger

class LogConfigurator {

    let level: XCGLogger.LogLevel

    init(level: XCGLogger.LogLevel) {
        self.level = level
    }

    func configure(log: XCGLogger) {

        log.setup(showThreadName: true, showLogLevel: true, showFileNames: true, showLineNumbers: true)
        log.removeLogDestination(XCGLogger.constants.baseConsoleLogDestinationIdentifier)

        let aslLog = XCGNSLogDestination(owner: log, identifier: XCGLogger.constants.nslogDestinationIdentifier)
        aslLog.outputLogLevel = level
        log.addLogDestination(aslLog)
    }
}
