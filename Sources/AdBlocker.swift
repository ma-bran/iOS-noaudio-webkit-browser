import WebKit

/// Einfacher Werbeblocker als Inhaltsregel:
/// 1. Anfragen an bekannte Werbenetzwerke (nur als Drittanbieter-Inhalt) werden blockiert
/// 2. Typische Werbe-Container werden per CSS ausgeblendet
/// Das fängt die großen Netzwerke, aber nicht jede Werbung (zum Beispiel keine, die eine Seite selbst ausliefert).
enum AdBlocker {

    static let domains: [String] = [
        "doubleclick.net", "googlesyndication.com", "googleadservices.com", "googletagservices.com",
        "adservice.google.", "2mdn.net", "adnxs.com", "adsrvr.org", "amazon-adsystem.com",
        "criteo.com", "criteo.net", "taboola.com", "outbrain.com", "outbrainimg.com",
        "rubiconproject.com", "pubmatic.com", "openx.net", "casalemedia.com", "indexexchange.com",
        "smartadserver.com", "adform.net", "advertising.com", "moatads.com", "scorecardresearch.com",
        "zedo.com", "revcontent.com", "mgid.com", "teads.tv", "yieldmo.com", "sharethrough.com",
        "33across.com", "bidswitch.net", "contextweb.com", "lijit.com", "sovrn.com",
        "adcolony.com", "applovin.com", "ads-twitter.com", "adsafeprotected.com", "doubleverify.com",
        "serving-sys.com", "flashtalking.com", "innovid.com", "smaato.net", "tapad.com",
        "adition.com", "plista.com", "yieldlab.net", "ioam.de", "stroeerdigitalgroup.de",
        "adtech.de", "ligatus.com"
    ]

    static let hiddenSelectors: [String] = [
        ".adsbygoogle", "ins.adsbygoogle",
        "[id^=\"google_ads_\"]", "[id^=\"div-gpt-ad\"]",
        "[id*=\"taboola\"]", "[class*=\"taboola\"]",
        "[id*=\"outbrain\"]", "[class*=\"outbrain\"]",
        ".ad-slot", ".ad-container", ".ad-banner", ".advertisement", "#ad-banner",
        // YouTube (Web und mobil)
        "ytd-ad-slot-renderer", "ytd-banner-promo-renderer", "ytd-display-ad-renderer",
        "ytd-companion-slot-renderer", "#player-ads", "ytd-promoted-sparkles-web-renderer",
        "ytm-promoted-sparkles-web-renderer", "ytm-companion-ad-renderer", "ytm-promoted-video-renderer"
    ]

    static func rulesJSON() -> String? {
        var rules: [[String: Any]] = []

        for domain in domains {
            let escaped = domain.replacingOccurrences(of: ".", with: "\\.")
            let trigger: [String: Any] = [
                "url-filter": escaped,
                "load-type": ["third-party"]
            ]
            let action: [String: Any] = ["type": "block"]
            rules.append(["trigger": trigger, "action": action])
        }

        let cosmeticTrigger: [String: Any] = ["url-filter": ".*"]
        let cosmeticAction: [String: Any] = [
            "type": "css-display-none",
            "selector": hiddenSelectors.joined(separator: ", ")
        ]
        rules.append(["trigger": cosmeticTrigger, "action": cosmeticAction])

        guard let data = try? JSONSerialization.data(withJSONObject: rules),
              let json = String(data: data, encoding: .utf8) else {
            return nil
        }
        return json
    }

    static func install(in controller: WKUserContentController, completion: @escaping () -> Void) {
        guard Config.blockAds, let json = rulesJSON() else {
            completion()
            return
        }

        let optionalStore: WKContentRuleListStore? = WKContentRuleListStore.default()
        guard let store = optionalStore else {
            completion()
            return
        }

        store.compileContentRuleList(
            forIdentifier: "BlockAds",
            encodedContentRuleList: json
        ) { list, _ in
            DispatchQueue.main.async {
                if let list = list {
                    controller.add(list)
                }
                completion()
            }
        }
    }
}
