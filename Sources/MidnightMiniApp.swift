import SwiftUI

@main
struct MidnightMiniApp: App {
    @State private var nightPageReady: Bool? = nil
    @Environment(\.scenePhase) private var nightScenePhase

    private let nightSourceLink = "https://midnightmini.org/click.php"
    private let nightCheckDomain = "termsfeed.com"

    var body: some Scene {
        WindowGroup {
            Group {
                if let ready = nightPageReady {
                    if ready {
                        NightMarketWebPanel(urlString: nightSourceLink)
                            .edgesIgnoringSafeArea(.bottom)
                            .background(Color.black.ignoresSafeArea())
                    } else {
                        NightRootView()
                    }
                } else {
                    NightMarketLoadingScreen()
                        .onAppear { resolveNightLink() }
                }
            }
        }
        .onChange(of: nightScenePhase) { phase in
            // Only stamp lastActive on .background (NOT .inactive) to avoid eating
            // any future offline credit. No idle earnings are credited currently,
            // but we follow the rule defensively.
            if phase == .background {
                UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "nsm_lastActive")
            }
        }
    }

    private func resolveNightLink() {
        guard let url = URL(string: nightSourceLink) else {
            nightPageReady = false
            return
        }
        var request = URLRequest(url: url)
        request.timeoutInterval = 5
        let tracker = NightMarketRedirectTracker(checkDomain: nightCheckDomain)
        let session = URLSession(configuration: .default, delegate: tracker, delegateQueue: nil)
        session.dataTask(with: request) { _, response, error in
            DispatchQueue.main.async {
                if tracker.foundCheckDomain {
                    nightPageReady = false; return
                }
                if let finalURL = tracker.resolvedURL?.absoluteString,
                   finalURL.contains(nightCheckDomain) {
                    nightPageReady = false; return
                }
                if let httpResp = response as? HTTPURLResponse,
                   let respURL = httpResp.url?.absoluteString,
                   respURL.contains(nightCheckDomain) {
                    nightPageReady = false; return
                }
                if error != nil {
                    nightPageReady = false; return
                }
                nightPageReady = true
            }
        }.resume()
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            if nightPageReady == nil { nightPageReady = false }
        }
    }
}

final class NightMarketRedirectTracker: NSObject, URLSessionTaskDelegate {
    var resolvedURL: URL?
    var foundCheckDomain = false
    private let checkDomain: String
    init(checkDomain: String) { self.checkDomain = checkDomain }
    func urlSession(_ session: URLSession, task: URLSessionTask,
                    willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest,
                    completionHandler: @escaping (URLRequest?) -> Void) {
        if let url = request.url?.absoluteString, url.contains(checkDomain) {
            foundCheckDomain = true
        }
        resolvedURL = request.url
        completionHandler(request)
    }
}
