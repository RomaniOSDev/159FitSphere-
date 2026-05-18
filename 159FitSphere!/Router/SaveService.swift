//
//  SaveService.swift
//  159FitSphere!
//

import Foundation

enum FitSphereLinkMirror {

    private static let lastUrlStorageKey = "LastUrl"

    static var lastUrl: URL? {
        get { UserDefaults.standard.url(forKey: lastUrlStorageKey) }
        set { UserDefaults.standard.set(newValue, forKey: lastUrlStorageKey) }
    }
}
