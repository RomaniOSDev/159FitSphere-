//
//  PersistenceManager.swift
//  159FitSphere!
//

import Foundation

final class FitSphereRouteVault {
    static let shared = FitSphereRouteVault()

    private let savedUrlKey = "LastUrl"
    private let hasShownContentViewKey = "HasShownContentView"
    private let hasSuccessfulWebViewLoadKey = "HasSuccessfulWebViewLoad"

    var savedUrl: String? {
        get {
            if let url = FitSphereLinkMirror.lastUrl {
                return url.absoluteString
            }
            return UserDefaults.standard.string(forKey: savedUrlKey)
        }
        set {
            if let urlString = newValue {
                UserDefaults.standard.set(urlString, forKey: savedUrlKey)
                if let url = URL(string: urlString) {
                    FitSphereLinkMirror.lastUrl = url
                }
            } else {
                UserDefaults.standard.removeObject(forKey: savedUrlKey)
                FitSphereLinkMirror.lastUrl = nil
            }
        }
    }

    var hasShownContentView: Bool {
        get {
            UserDefaults.standard.bool(forKey: hasShownContentViewKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: hasShownContentViewKey)
        }
    }

    var hasSuccessfulWebViewLoad: Bool {
        get {
            UserDefaults.standard.bool(forKey: hasSuccessfulWebViewLoadKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: hasSuccessfulWebViewLoadKey)
        }
    }

    private init() {}
}
