import SwiftUI
import WebKit

struct ContentView: View {
    @State private var showWebView = false
    @State private var isRefreshing = false
    private let urlString: String = "https://apps.ssayomart.com"

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
    private let urlString: String = "https://apps.ssayomart.com"

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
        let userAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X) AppleWebKit/603.1.30 (KHTML, like Gecko) Version/12.0.0 Mobile/15A5370a Safari/602.1"
                
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")

        webView.load(request)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        refreshControl.endRefreshing()
    }
}
