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
    private let urlString: String = "https://ssayomart.com/homepage-mobile"
    
    var body: some View {
        VStack(spacing: 40) {
            if showWebView {
                CustomWebView(url: URL(string: urlString)!, isRefreshing: $isRefreshing)
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
        .padding()
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

class CustomWebViewController: UIViewController, WKNavigationDelegate, UITextFieldDelegate, UITextViewDelegate, WKUIDelegate {
    private var url: URL
    private var webView: WKWebView!
    private var preloaderImageView: UIImageView!
    private var refreshControl: UIRefreshControl!
    private var isInputActive = false
    private var activeInputElementID: String?
    

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
        // Tambahkan observer untuk memantau halaman web
        webView.addObserver(self, forKeyPath: "estimatedProgress", options: .new, context: nil)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
            if keyPath == "loading", let newValue = change?[.newKey] as? Bool, !newValue {
                // ...
            } else if keyPath == "estimatedProgress" {
                // Cek apakah ada input teks aktif pada WebView
                webView.evaluateJavaScript("document.activeElement.tagName") { [weak self] result, _ in
                    if let tagName = result as? String, tagName == "INPUT" || tagName == "TEXTAREA" {
                        self?.isInputActive = true
                        // Mendapatkan ID dari elemen input yang aktif
                        self?.webView.evaluateJavaScript("document.activeElement.id") { id, _ in
                            self?.activeInputElementID = id as? String
                            self?.disableZoomAccordingToInputState()
                        }
                    } else {
                        self?.isInputActive = false
                        self?.activeInputElementID = nil
                        self?.disableZoomAccordingToInputState()
                    }
                }
            }
        }
    
    private func disableZoomAccordingToInputState() {
            if let activeID = activeInputElementID {
                // Mengatur zooming berdasarkan elemen input aktif
                let js = "document.getElementById('\(activeID)').blur();"
                webView.evaluateJavaScript(js, completionHandler: nil)
                
                // Menonaktifkan zooming hanya jika elemen input aktif
                webView.scrollView.maximumZoomScale = isInputActive ? 1.0 : 10.0
                webView.scrollView.minimumZoomScale = 1.0
                webView.scrollView.bouncesZoom = !isInputActive
            } else {
                // Menonaktifkan zooming berdasarkan flag isInputActive jika tidak ada elemen input aktif
                webView.scrollView.maximumZoomScale = isInputActive ? 1.0 : 10.0
                webView.scrollView.minimumZoomScale = 1.0
                webView.scrollView.bouncesZoom = !isInputActive
            }
        }
    
    private func setupViews() {
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshWebView), for: .valueChanged)
        
        // Inisialisasi WKUserScript untuk mematikan zooming
        let source = "var meta = document.createElement('meta');" +
                         "meta.name = 'viewport';" +
                         "meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';" +
                         "var head = document.getElementsByTagName('head')[0];" +
                         "head.appendChild(meta);"
        let script = WKUserScript(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        let userContentController = WKUserContentController()
        userContentController.addUserScript(script)
        let conf = WKWebViewConfiguration()
        conf.userContentController = userContentController
        
        // Inisialisasi WKWebView dengan konfigurasi yang telah dibuat
        webView = WKWebView(frame: .zero, configuration: conf)
        webView.scrollView.addSubview(refreshControl)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.isHidden = true
        
        // Menambahkan observer untuk mengatur flag isInputActive
        webView.addObserver(self, forKeyPath: "loading", options: .new, context: nil)
                
        // Menonaktifkan zooming
        webView.scrollView.maximumZoomScale = 1.0
        webView.scrollView.minimumZoomScale = 1.0
        webView.scrollView.bouncesZoom = false
                
        // Menambahkan gesture recognizer untuk mencegah double tap
        for subview in webView.scrollView.subviews {
            if let subviewGestures = subview.gestureRecognizers {
                for gesture in subviewGestures {
                    if gesture is UITapGestureRecognizer {
                        gesture.isEnabled = false
                    }
                }
            }
        }
        
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
        webView.isHidden = false
        
        refreshControl.endRefreshing()
    }

}
