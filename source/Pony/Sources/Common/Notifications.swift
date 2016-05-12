//
// Created by Denis Dorokhov on 10/05/16.
// Copyright (c) 2016 Denis Dorokhov. All rights reserved.
//

import Foundation

class Notifications {

    private static let notificationCenter = NSNotificationCenter.defaultCenter()

    private static var tokenToObservers: [NSValue: [NSObjectProtocol]] = [:]

    class func publish(name: String, object: AnyObject? = nil, userInfo: [NSObject : AnyObject]? = nil) {
        notificationCenter.postNotificationName(name, object: object, userInfo: userInfo)
    }

    class func subscribe(name: String, _ token: AnyObject, object: AnyObject? = nil, queue: NSOperationQueue? = nil, handler: NSNotification -> Void) {
        let key = NSValue(nonretainedObject: token)
        var observers = tokenToObservers[key] ?? []
        observers.append(notificationCenter.addObserverForName(name, object: object, queue: queue, usingBlock: handler))
        tokenToObservers[key] = observers
    }

    class func unsubscribe(token: AnyObject) {
        if let observers = tokenToObservers[NSValue(nonretainedObject: token)] {
            for token in observers {
                notificationCenter.removeObserver(token)
            }
        }
    }
}
