//import SwiftUI
//import AVKit
//
//struct WebVideoPlayer: UIViewRepresentable {
//    let embedURL: String
//    
//    func makeUIView(context: Context) -> WKWebView {
//        let webView = WKWebView()
//        webView.navigationDelegate = context.coordinator
//        
//        // Configure for video playback
//        webView.configuration.allowsInlineMediaPlayback = true
//        webView.configuration.mediaTypesRequiringUserActionForPlayback = []
//        
//        // Load the embed URL
//        if let url = URL(string: embedURL) {
//            let request = URLRequest(url: url)
//            webView.load(request)
//        }
//        
//        return webView
//    }
//    
//    func updateUIView(_ webView: WKWebView, context: Context) {
//        // Update if needed
//    }
//    
//    func makeCoordinator() -> Coordinator {
//        Coordinator()
//    }
//    
//    class Coordinator: NSObject, WKNavigationDelegate {
//        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
//            print("Video player loaded successfully")
//        }
//        
//        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
//            print("Video player failed to load: \(error.localizedDescription)")
//        }
//    }
//}
