//
// Created by Denis Dorokhov on 30/04/16.
// Copyright (c) 2016 Denis Dorokhov. All rights reserved.
//

import Foundation
import OrderedSet
import SwiftyTimer
import XCGLogger

protocol AuthServiceDelegate: class {
    func authService(authService: AuthService, didAuthenticateUser user: User)
    func authService(authService: AuthService, didUpdateUser user: User)
    func authService(authService: AuthService, didLogoutUser user: User)
}

class AuthService {

    private let REFRESH_TOKEN_TIME_BEFORE_EXPIRATION = 60 * 60
    private let ACCESS_TOKEN_EXPIRATION_CHECK_INTERVAL = 10

    private let log = XCGLogger.defaultInstance()

    var tokenPairDao: TokenPairDao!
    var restService: RestService!

    var isAuthenticated: Bool {
        return currentUser != nil
    }

    private(set) var currentUser: User?

    private var delegates: OrderedSet<NSValue> = []

    private var refreshTokenRequest: RestRequest?
    private var authenticationRequest: RestRequest?
    private var updateUserRequest: RestRequest?

    func addDelegate(delegate: AuthServiceDelegate) {
        delegates.append(NSValue(nonretainedObject: delegate))
    }

    func removeDelegate(delegate: AuthServiceDelegate) {
        delegates.remove(NSValue(nonretainedObject: delegate))
    }

    func authenticate(credentials: Credentials,
                      onSuccess: (User -> Void)? = nil,
                      onFailure: ([Error] -> Void)? = nil) {

        if isAuthenticated {
            log.warning("User is already authenticated, logging out...")
            logout()
        }

        log.info("Authenticating user '\(credentials.email)'...")

        updateUserRequest?.cancel()
        updateUserRequest = nil

        refreshTokenRequest?.cancel()
        refreshTokenRequest = nil

        authenticationRequest?.cancel()
        authenticationRequest = restService.authenticate(credentials, onSuccess: {
            authentication in

            self.authenticationRequest = nil

            self.updateAuthentication(authentication)

            self.log.info("User '\(authentication.user.email)' has authenticated.")

            onSuccess?(authentication.user)
            self.propagateAuthentication(authentication.user)

        }, onFailure: {
            errors in

            self.authenticationRequest = nil

            self.log.info("Authentication failed for user '\(credentials.email)': \(errors)")

            onFailure?(errors)
        })
    }

    func updateUser(onSuccess onSuccess: (User -> Void)? = nil,
                    onFailure: ([Error] -> Void)? = nil) {

        if tokenPairDao.fetchTokenPair() != nil {

            log.info("Updating authentication status...")

            authenticationRequest?.cancel()
            authenticationRequest = nil

            updateUserRequest?.cancel()
            updateUserRequest = restService.getCurrentUser(onSuccess: {
                user in

                self.currentUser = user

                self.updateUserRequest = nil

                self.log.info("User '\(user.email)' is authenticated.")

                onSuccess?(user)
                self.propagateUserUpdate(user)

            }, onFailure:  {
                self.updateUserRequest = nil
                self.onUpdateUserRequestFailure($0, onSuccess: onSuccess, onFailure: onFailure)
            })

        } else {
            log.info("Skipping status update: no token found.")
            onFailure?([Error.accessDenied])
        }
    }

    func logout(onSuccess onSuccess: (User -> Void)? = nil,
                onFailure: ([Error] -> Void)? = nil) {

        authenticationRequest?.cancel()
        authenticationRequest = nil

        updateUserRequest?.cancel()
        updateUserRequest = nil

        refreshTokenRequest?.cancel()
        refreshTokenRequest = nil

        if let lastUser = currentUser {

            log.info("Logging out user '\(lastUser.email)'...")

            restService.logout(onSuccess: {
                onSuccess?($0)
            }, onFailure: {
                self.log.error("Could not log out: \($0).")
                onFailure?($0)
            })

            clearAuthentication()

            log.info("User '\(lastUser.email)' has logged out.")
            propagateLogout(lastUser)

        } else {

            clearAuthentication()

            log.info("Skipping log out: user is not authenticated.")
            onFailure?([Error.accessDenied])
        }
    }

    func checkAccessTokenExpiration(handler: (Void -> Void)? = nil) {
        if let accessTokenExpiration = tokenPairDao.fetchTokenPair()?.accessTokenExpiration.timeIntervalSinceNow {
            if refreshTokenRequest == nil && authenticationRequest == nil && accessTokenExpiration <= Double(REFRESH_TOKEN_TIME_BEFORE_EXPIRATION) {
                refreshToken(onSuccess: {
                    authentication in
                    self.propagateUserUpdate(authentication.user)
                    handler?()
                }, onFailure: {
                    errors in
                    handler?()
                })
            } else {
                handler?()
            }
        } else {
            handler?()
        }
    }

    private func onUpdateUserRequestFailure(errors: [Error],
                                            onSuccess: (User -> Void)?,
                                            onFailure: ([Error] -> Void)?) {
        if Error.fetchFirstByCodes([
                Error.CODE_CLIENT_REQUEST_FAILED,
                Error.CODE_CLIENT_REQUEST_CANCELLED,
                Error.CODE_CLIENT_REQUEST_TIMEOUT,
                Error.CODE_CLIENT_OFFLINE], fromArray: errors) != nil {

            log.error("Could not update authentication status (client error): \(errors).")
            onFailure?(errors)

        } else if Error.fetchFirstByCodes([Error.CODE_ACCESS_DENIED], fromArray: errors) != nil {

            if refreshTokenRequest == nil {
                log.info("Could not update authentication status, access is denied, trying to refresh token...")
                refreshToken(onSuccess: {
                    authentication in
                    onSuccess?(authentication.user)
                    self.propagateUserUpdate(authentication.user)
                }, onFailure: onFailure)
            } else {
                onFailure?(errors)
            }

        } else {
            log.error("Could not update authentication status (server error): \(errors).")
            onFailure?(errors)
        }
    }

    private func updateAuthentication(authentication: Authentication) {
        tokenPairDao.storeTokenPair(TokenPair(authentication: authentication))
        currentUser = authentication.user
    }

    private func clearAuthentication() {
        tokenPairDao.removeTokenPair()
        currentUser = nil
    }

    private func refreshToken(onSuccess onSuccess: (Authentication -> Void)?, onFailure: ([Error] -> Void)?) {
        if tokenPairDao.fetchTokenPair() != nil {

            log.info("Refreshing access token...")

            refreshTokenRequest?.cancel()
            refreshTokenRequest = restService.refreshToken(onSuccess: {
                authentication in

                self.refreshTokenRequest = nil

                self.updateAuthentication(authentication)

                self.log.info("Token for user '\(authentication.user.email)' has been refreshed.")

                onSuccess?(authentication)

            }, onFailure: {
                errors in

                self.refreshTokenRequest = nil

                self.log.error("Could not refresh token: \(errors)")

                onFailure?(errors)

                if Error.fetchFirstByCodes([Error.CODE_ACCESS_DENIED], fromArray: errors) != nil {

                    let lastUser = self.currentUser

                    self.clearAuthentication()
                    if let lastUser = lastUser {
                        self.propagateLogout(lastUser)
                    }
                }
            })

        } else {
            log.info("Skipping token refresh: no token found.")
            onFailure?([Error.accessDenied])
        }
    }

    private func scheduleAccessTokenExpirationCheck() {
        NSTimer.after(10.seconds) {
            [weak self] in
            if self?.isAuthenticated ?? false {
                self?.checkAccessTokenExpiration {
                    self?.scheduleAccessTokenExpirationCheck()
                }
            } else {
                self?.scheduleAccessTokenExpirationCheck()
            }
        }
    }

    private func propagateAuthentication(user: User) {
        for delegate in fetchDelegates() {
            delegate.authService(self, didAuthenticateUser: user)
        }
    }

    private func propagateUserUpdate(user: User) {
        for delegate in fetchDelegates() {
            delegate.authService(self, didUpdateUser: user)
        }
    }

    private func propagateLogout(user: User) {
        for delegate in fetchDelegates() {
            delegate.authService(self, didLogoutUser: user)
        }
    }

    private func fetchDelegates() -> [AuthServiceDelegate] {
        return delegates.map { $0.nonretainedObjectValue as! AuthServiceDelegate }
    }

}
