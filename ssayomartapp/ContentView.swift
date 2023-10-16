import SwiftUI
import WebKit

public class UserAgent {
    public static let userAgent: String? = {
        guard let info = Bundle.main.infoDictionary,
            let appNameRaw = info["Ssayomart"] ??  info[kCFBundleIdentifierKey as String],
            let appVersionRaw = info[kCFBundleVersionKey as String],
            let appName = appNameRaw as? String,
            let appVersion = appVersionRaw as? String
        else { return nil }

        #if canImport(UIKit)
        let scale: String
        if #available(iOS 4, *) {
            scale = String(format: "%0.2f", UIScreen.main.scale)
        } else {
            scale = "1.0"
        }

        let model = UIDevice.current.model
        let os = UIDevice.current.systemVersion
        let ua = "\(appName)/\(appVersion) (\(model); iOS \(os); Scale/\(scale))"
        #else
        let ua = "\(appName)/\(appVersion)"
        #endif

        return ua
    }()
}


struct ContentView: View {
    @State private var showWebView = false
    @State private var isRefreshing = false
    private let urlString: String = "http://localhost:8080"

    var body: some View {
        VStack(spacing: 2) {
            if showWebView {
                CustomWebView(url: URL(string: urlString)!, isRefreshing: $isRefreshing)
                    .ignoresSafeArea()
            } else {
                Image("logo")
                    .resizable()
                    .frame(width: 100, height: 100)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            showWebView = true
                        }
                    }
            }
        }
    }
}

struct CustomWebView: UIViewControllerRepresentable {
    var url: URL
    @Binding var isRefreshing: Bool

    func makeUIViewController(context: Context) -> some UIViewController {
        let webViewController = CustomWebViewController(url: url)
        return webViewController
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        // No need for updates here
    }
}

class CustomWebViewController: UIViewController, WKNavigationDelegate, WKUIDelegate {
    private var url: URL
    private var webView: WKWebView!
    private var refreshControl: UIRefreshControl!

    init(url: URL) {
        self.url = url
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        loadWebView()
    }

    private func setupViews() {
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshWebView), for: .valueChanged)

        let conf = WKWebViewConfiguration()
        
        // Inisialisasi WKWebView dengan konfigurasi yang telah dibuat
        webView = WKWebView(frame: .zero, configuration: conf)
        webView.scrollView.addSubview(refreshControl)
        webView.navigationDelegate = self
        webView.uiDelegate = self

        view.addSubview(webView)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        webView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        webView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        webView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    }

    @objc private func refreshWebView() {
        webView.reload()
    }

    private func loadWebView() {
        var request = URLRequest(url: url)
        
        // Menambahkan header User-Agent
        let userAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 13_2_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.3 Mobile/15E148 Safari/604.1"
                       
        webView.customUserAgent = userAgent

        webView.load(request)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        refreshControl.endRefreshing()
    }
}
