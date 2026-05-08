//
//  AppDelegate.swift
//  159FitSphere!
//
//  Created by Roman on 5/8/26.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FitSphereAppearance.configure()
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    }
}

private enum FitSphereAppearance {

    static func configure() {
        let textPrimary = UIColor(named: "AppTextPrimary") ?? .white
        let textSecondary = UIColor(named: "AppTextSecondary") ?? .lightGray
        let primary = UIColor(named: "AppPrimary") ?? .systemOrange
        let surface = UIColor(named: "AppSurface") ?? .darkGray
        let background = UIColor(named: "AppBackground") ?? .black

        let navigationBar = UINavigationBarAppearance()
        navigationBar.configureWithOpaqueBackground()
        navigationBar.backgroundColor = surface
        navigationBar.titleTextAttributes = [.foregroundColor: textPrimary]
        navigationBar.largeTitleTextAttributes = [.foregroundColor: textPrimary]

        let navigationBarProxy = UINavigationBar.appearance()
        navigationBarProxy.standardAppearance = navigationBar
        navigationBarProxy.scrollEdgeAppearance = navigationBar
        navigationBarProxy.compactAppearance = navigationBar
        navigationBarProxy.compactScrollEdgeAppearance = navigationBar
        navigationBarProxy.tintColor = primary

        let segmented = UISegmentedControl.appearance()
        segmented.backgroundColor = background.withAlphaComponent(0.35)
        segmented.selectedSegmentTintColor = primary
        segmented.setTitleTextAttributes([.foregroundColor: textPrimary], for: .selected)
        segmented.setTitleTextAttributes([.foregroundColor: textSecondary], for: .normal)

        UILabel.appearance(whenContainedInInstancesOf: [UITableViewHeaderFooterView.self]).textColor = textSecondary

        UITextField.appearance().textColor = textPrimary
        UITextField.appearance().tintColor = primary

        UITableView.appearance().backgroundColor = .clear

        UISwitch.appearance().onTintColor = primary
    }
}
