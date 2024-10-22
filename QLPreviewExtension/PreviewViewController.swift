//
//  PreviewViewController.swift
//  QLProvision
//
//  Created by zhouziyuan on 2022/9/21.
//

import Cocoa
import Quartz
import WebKit

class PreviewViewController: NSViewController, QLPreviewingController {
    var webView: WKWebView  = WKWebView(frame: .zero)

    override func loadView() {
        super.loadView()
        preferredContentSize = NSSize(width: 640, height: 800)
        updateViewConstraints()
        self.view = NSView()
        self.view.addSubview(webView)
        webView.allowsMagnification  = true
        webView.autoresizingMask = [.width, .height]
        webView.translatesAutoresizingMaskIntoConstraints = true
    }
    
    func preparePreviewOfFile(at url: URL, completionHandler handler: @escaping (Error?) -> Void) {
        webView.stopLoading()
        webView.load(URLRequest(url: URL(string: "about:blank")!))
        do {
            let file = try Preview(url: url)
            let html = try file.run()
            DispatchQueue.main.async { [weak self] in
                self?.webView.loadHTMLString(html, baseURL: nil)
            }
            handler(nil)
        } catch {
            handler(error)
        }
    }
    override func viewWillDisappear() {
      super.viewWillDisappear()
      
      // Stop loading and clear the web view when the view is about to disappear
      webView.stopLoading()
      webView.load(URLRequest(url: URL(string: "about:blank")!))
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
      print("Navigation failure: \(error.localizedDescription)")
    }
}
