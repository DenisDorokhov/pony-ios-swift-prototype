//
// Created by Denis Dorokhov on 01/05/16.
// Copyright (c) 2016 Denis Dorokhov. All rights reserved.
//

import Foundation
import XCGLogger
import OrderedSet

protocol BootstrapServiceDelegate: class {

    func bootstrapServiceDidStartBootstrap(bootstrapService: BootstrapService)
    func bootstrapServiceDidFinishBootstrap(bootstrapService: BootstrapService)

    func bootstrapServiceDidStartBackgroundActivity(bootstrapService: BootstrapService)

    func bootstrapServiceDidRequireRestUrl(bootstrapService: BootstrapService)
    func bootstrapServiceDidRequireAuthentication(bootstrapService: BootstrapService)

    func bootstrapService(bootstrapService: BootstrapService, didFailWithErrors errors: [ErrorDto])
}

class BootstrapService {

    private let log = XCGLogger.defaultInstance()

    var restUrlDao: RestUrlDao!
    var restService: RestService!
    var authService: AuthService!

    private var delegates: OrderedSet<NSValue> = []

    private var isBootstrapping: Bool = false

    func addDelegate(delegate: BootstrapServiceDelegate) {
        delegates.append(NSValue(nonretainedObject: delegate))
    }

    func removeDelegate(delegate: BootstrapServiceDelegate) {
        delegates.remove(NSValue(nonretainedObject: delegate))
    }

    func bootstrap() {
        if !isBootstrapping {

            log.info("Bootstrapping...")

            isBootstrapping = true

            for delegate in fetchDelegates() {
                delegate.bootstrapServiceDidStartBootstrap(self)
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
                    delegate.bootstrapServiceDidRequireRestUrl(self)
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
            delegate.bootstrapServiceDidStartBackgroundActivity(self)
        }

        authService.updateUser(onSuccess: {
            user in
            self.isBootstrapping = false
            self.propagateDidFinishBootstrap()
        }, onFailure: {
            errors in
            self.isBootstrapping = false
            if ErrorDto.fetchFirstByCodes([ErrorDto.CODE_ACCESS_DENIED], fromArray: errors) != nil {
                self.log.info("Bootstrapping requires authentication.")
                for delegate in self.fetchDelegates() {
                    delegate.bootstrapServiceDidRequireAuthentication(self)
                }
            } else {
                for delegate in self.fetchDelegates() {
                    delegate.bootstrapService(self, didFailWithErrors: errors)
                }
            }
        })
    }

    private func fetchDelegates() -> [BootstrapServiceDelegate] {
        return delegates.map { $0.nonretainedObjectValue as! BootstrapServiceDelegate }
    }

    private func propagateDidFinishBootstrap() {
        log.info("Bootstrap finished.")
        for delegate in fetchDelegates() {
            delegate.bootstrapServiceDidFinishBootstrap(self)
        }
    }

}
