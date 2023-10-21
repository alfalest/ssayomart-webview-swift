import SwiftUI
import WebKit

struct ContentView: View {
    @State private var showWebView = false
    @State private var isRefreshing = false
    private let urlString: String = "https://apps.ssayomart.com"

    var body: some View {
        VStack(spacing: 10) { // Menambahkan spasi antara elemen
            if showWebView {
                CustomWebView(url: URL(string: urlString)!, isRefreshing: $isRefreshing)
                    .ignoresSafeArea()
            } else {
                LogoPreloaderView()
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
        let webViewController = CustomWebViewController(url: url, isRefreshing: $isRefreshing)
        return webViewController
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        // No need for updates here
    }
}

struct LogoPreloaderView: View {
    @State private var showLogo = false
    var body: some View {
        VStack {
            if showLogo {
                Image("logo")
                    .resizable()
                    .frame(width: 80, height: 80)
                    .scaleEffect(1.5) // Efek zoom in
                    .animation(.easeIn(duration: 0.5))
                } else {
                Image("logo")
                    .resizable()
                    .frame(width: 80, height: 80)
                    .scaleEffect(1.5)
                    .opacity(0) // Logo akan dimulai dengan opacity 0
                    .onAppear {
                        withAnimation {
                            showLogo = true
                        }
                    }
                }
            ProgressView().padding(.top, 25)
                .scaleEffect(2.0) // Memperbesar ukuran loading spinner
        }
    }
}

class CustomWebViewController: UIViewController, WKNavigationDelegate, WKUIDelegate {
    private var url: URL
    private var webView: WKWebView!
    private var refreshControl: UIRefreshControl!
    @Binding var isRefreshing: Bool

    init(url: URL, isRefreshing: Binding<Bool>) {
        self.url = url
        self._isRefreshing = isRefreshing
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

        refreshControl.addTarget(self, action: #selector(pullToRefresh), for: .valueChanged)

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

    @objc private func pullToRefresh() {
        isRefreshing = true
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
        isRefreshing = false
        refreshControl.endRefreshing()
    }
}
