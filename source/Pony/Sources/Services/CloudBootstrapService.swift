//
// Created by Denis Dorokhov on 01/05/16.
// Copyright (c) 2016 Denis Dorokhov. All rights reserved.
//

import Foundation
import XCGLogger
import OrderedSet

protocol CloudBootstrapServiceDelegate: class {

    func cloudBootstrapServiceDidStartBootstrap(cloudBootstrapService: CloudBootstrapService)
    func cloudBootstrapServiceDidFinishBootstrap(cloudBootstrapService: CloudBootstrapService)

    func cloudBootstrapServiceDidStartBackgroundActivity(cloudBootstrapService: CloudBootstrapService)

    func cloudBootstrapServiceDidRequireRestUrl(cloudBootstrapService: CloudBootstrapService)
    func cloudBootstrapServiceDidRequireAuthentication(cloudBootstrapService: CloudBootstrapService)

    func cloudBootstrapService(cloudBootstrapService: CloudBootstrapService, didFailWithErrors errors: [Error])
}

class CloudBootstrapService {

    private let log = XCGLogger.defaultInstance()

    var restUrlDao: RestUrlDao!
    var authService: AuthService!

    private var delegates: OrderedSet<NSValue> = []

    private var isBootstrapping: Bool = false

    func addDelegate(delegate: CloudBootstrapServiceDelegate) {
        delegates.append(NSValue(nonretainedObject: delegate))
    }

    func removeDelegate(delegate: CloudBootstrapServiceDelegate) {
        delegates.remove(NSValue(nonretainedObject: delegate))
    }

    func bootstrap() {
        if !isBootstrapping {

            log.info("Bootstrapping...")

            isBootstrapping = true

            for delegate in fetchDelegates() {
                delegate.cloudBootstrapServiceDidStartBootstrap(self)
            }

            if restUrlDao.fetchUrl() != nil {

                if (authService.isAuthenticated) {
                    isBootstrapping = false
                    propagateDidFinishBootstrap()
                } else {
                    validateAuthentication()
                }

            } else {

                isBootstrapping = false
                log.info("Bootstrapping requires server URL.")

                for delegate in fetchDelegates() {
                    delegate.cloudBootstrapServiceDidRequireRestUrl(self)
                }
            }
        } else {
            log.warning("Could not bootstrap: already bootstrapping.")
        }
    }

    func clearBootstrapData() {
        log.info("Clearing bootstrap data.")
        authService.logout()
        restUrlDao.removeUrl()
    }

    private func validateAuthentication() {

        for delegate in fetchDelegates() {
            delegate.cloudBootstrapServiceDidStartBackgroundActivity(self)
        }

        authService.updateUser(onSuccess: {
            user in
            self.isBootstrapping = false
            self.propagateDidFinishBootstrap()
        }, onFailure: {
            errors in
            self.isBootstrapping = false
            if Error.fetchFirstByCodes([Error.CODE_ACCESS_DENIED], fromArray: errors) != nil {
                self.log.info("Bootstrapping requires authentication.")
                for delegate in self.fetchDelegates() {
                    delegate.cloudBootstrapServiceDidRequireAuthentication(self)
                }
            } else {
                for delegate in self.fetchDelegates() {
                    delegate.cloudBootstrapService(self, didFailWithErrors: errors)
                }
            }
        })
    }

    private func fetchDelegates() -> [CloudBootstrapServiceDelegate] {
        return delegates.map { $0.nonretainedObjectValue as! CloudBootstrapServiceDelegate
        }
    }

    private func propagateDidFinishBootstrap() {
        log.info("Bootstrap finished.")
        for delegate in fetchDelegates() {
            delegate.cloudBootstrapServiceDidFinishBootstrap(self)
        }
    }

}
