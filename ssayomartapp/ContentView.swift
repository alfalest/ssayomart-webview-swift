import SwiftUI
import WebKit
import CoreLocation
import Foundation
import Combine
import SystemConfiguration

struct ContentView: View {
    @State private var showWebView = false
    @State private var isRefreshing = false
    @State private var isInternetAvailable = true
        private let urlString: String = "https://apps.ssayomart.com"
//    private let urlString: String = "https://public-dev.ssayomart.com"
    
    var body: some View {
        VStack(spacing: 0) {
            if isInternetAvailable {
                if showWebView {
                    CustomWebView(url: URL(string: urlString)!, isRefreshing: $isRefreshing, isInternetAvailable: $isInternetAvailable)
                        .ignoresSafeArea()
                } else {
                    LogoPreloaderView(
                        showWebView: $showWebView,
                        isInternetAvailable: $isInternetAvailable,
                        refreshAction: {
                            checkInternetConnection()
                            if isInternetAvailable {
                                showWebView = true
                            }
                        }
                    )
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            showWebView = true
                        }
                    }
                }
            } else {
                Text("Internet Tidak Terdeteksi | No Internet")
                    .foregroundColor(.red)
                    .font(.headline)
                    .padding()
            }
        }
        }
        
        private func checkInternetConnection() {
            isInternetAvailable = ConnectivityHelper.shared.isConnected
        }
        
        struct CustomWebView: UIViewControllerRepresentable {
            var url: URL
            @Binding var isRefreshing: Bool
            @Binding var isInternetAvailable: Bool
            
            func makeUIViewController(context: Context) -> some UIViewController {
                let webViewController = CustomWebViewController(url: url, isRefreshing: $isRefreshing, isInternetAvailable: $isInternetAvailable)
                return webViewController
            }
            
            func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
                // No need for updates here
            }
        }
        
    struct LogoPreloaderView: View {
        @Binding var showWebView: Bool
        @Binding var isInternetAvailable: Bool
        var refreshAction: () -> Void
        @State private var showLogo = false

        var body: some View {
            VStack {
                if showLogo {
                    Image("logo")
                        .resizable()
                        .frame(width: 80, height: 80)
                        .scaleEffect(1.5)
                        .animation(.easeIn(duration: 0.5))
                } else {
                    Image("logo")
                        .resizable()
                        .frame(width: 80, height: 80)
                        .scaleEffect(1.5)
                        .opacity(0)
                        .onAppear {
                            withAnimation {
                                showLogo = true
                            }
                        }
                }
                ProgressView().padding(.top, 25)
                    .scaleEffect(2.0)

                if !showLogo {
                    Button(action: {
                        refreshAction()
                    }) {
                        Text("Refresh")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                    .padding(.top, 16)
                }
            }
        }
    }


    
    class CustomWebViewController: UIViewController, WKNavigationDelegate, WKUIDelegate, CLLocationManagerDelegate, UIScrollViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        private var url: URL
        private var webView: WKWebView!
        private var refreshControl: UIRefreshControl!
        private var locationManager: CLLocationManager!
        private var imagePicker: UIImagePickerController!
        @Binding var isRefreshing: Bool
        @Binding var isInternetAvailable: Bool  // Added
        
        init(url: URL, isRefreshing: Binding<Bool>, isInternetAvailable: Binding<Bool>) {  // Updated
            self.url = url
            self._isRefreshing = isRefreshing
            self._isInternetAvailable = isInternetAvailable  // Updated
            super.init(nibName: nil, bundle: nil)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func viewDidLoad() {
            super.viewDidLoad()
            setupViews()
            setupLocationManager()
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
            
            // Set delegate scrollView ke self
            webView.scrollView.delegate = self
            
            // Menonaktifkan zoom
            webView.scrollView.bouncesZoom = false
            webView.scrollView.isScrollEnabled = true
            
            // Tambahkan gesture recognizer untuk menangani tap
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture(_:)))
            webView.addGestureRecognizer(tapGesture)
            
            view.addSubview(webView)
            webView.translatesAutoresizingMaskIntoConstraints = false
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
            webView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
            
            let contentController = WKUserContentController()
            contentController.addUserScript(WKUserScript(source: "document.documentElement.style.webkitTouchCallout='none';", injectionTime: .atDocumentEnd, forMainFrameOnly: true))
            conf.userContentController = contentController
            
        }
        
        @objc private func pullToRefresh() {
            isRefreshing = true
            webView.reload()
        }
        
        private func setupLocationManager() {
            locationManager = CLLocationManager()
            locationManager.delegate = self
            locationManager.requestWhenInUseAuthorization()
        }
        
        private func loadWebView() {
            var request = URLRequest(url: url)
            
            // Menambahkan header User-Agent
            let userAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 13_2_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.3 Mobile/15E148 Safari/604.1"
            
            webView.customUserAgent = userAgent
            webView.load(request)
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            if let nsError = error as? NSError, nsError.domain == NSURLErrorDomain {
                isInternetAvailable = false
            }
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            isRefreshing = false
            refreshControl.endRefreshing()
        }
        func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
            if status == .authorizedWhenInUse {
                webView.reload()
            }
        }
        // Implementasi UIScrollViewDelegate
        func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
            scrollView.pinchGestureRecognizer?.isEnabled = false
        }
        
        func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
            scrollView.pinchGestureRecognizer?.isEnabled = true
            scrollView.setZoomScale(1.0, animated: false)
        }
        
        @objc private func handleTapGesture(_ gesture: UITapGestureRecognizer) {
            // Panggil fungsi untuk memilih gambar ketika tap terdeteksi
            selectImage()
        }
        
        private func selectImage() {
            imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = .photoLibrary
            present(imagePicker, animated: true, completion: nil)
        }
        
        // UIImagePickerControllerDelegate method untuk menangani pemilihan gambar
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let pickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
                // Handle gambar yang dipilih di sini, misalnya mengirimnya ke server atau menampilkan di WebView
            }
            
            dismiss(animated: true, completion: nil)
        }
        
    }
}
