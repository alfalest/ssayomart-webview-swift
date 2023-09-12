//
//  ContentView.swift
//  ssayomartapp
//
//  Created by ANEKA DASUIB JAYA on 04/08/23.
//

import SwiftUI
import WebKit

struct ContentView: View {
    @State private var showWebView = false
    @State private var isRefreshing = false
    private let urlString: String = "https://apps.ssayomart.com"
    
    var body: some View {
        VStack(spacing: 0) { // Menghilangkan spacing antar komponen
            if showWebView {
                CustomWebView(url: URL(string: urlString)!, isRefreshing: $isRefreshing)
                    .ignoresSafeArea() // Mengabaikan safe area agar penuh layar
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
        // Tidak perlu ada perubahan saat updateUIView
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
        let userContentController = WKUserContentController()
        
        // Inisialisasi WKUserScript untuk mematikan zooming
        let source = """
        var meta = document.createElement('meta');
        meta.name = 'viewport';
        meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
        var head = document.getElementsByTagName('head')[0];
        head.appendChild(meta);
        """
        let script = WKUserScript(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        userContentController.addUserScript(script)
        
        conf.userContentController = userContentController
        
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
   
    @objc private func refreshWebView(){
        webView.reload()
    }
    
    private func loadWebView() {
        let request = URLRequest(url: url)
        webView.load(request)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        refreshControl.endRefreshing()
    }
}
