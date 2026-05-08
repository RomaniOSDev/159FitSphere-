import Foundation

/// Central place for user-facing URLs and mailto links. Update strings before release.
enum AppExternalLink: String {
    case privacyPolicy = "https://fitspherea159.site/privacy/154"
    case supportEmail = "https://fitspherea159.site/terms/154"

    var url: URL? {
        URL(string: rawValue)
    }
}
