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
    @IBOutlet var webView: WKWebView!

    override var nibName: NSNib.Name? {
        return NSNib.Name("PreviewViewController")
    }

    override func loadView() {
        super.loadView()
        preferredContentSize = NSSize(width: 640, height: 800)
        updateViewConstraints()
        
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func preparePreviewOfFile(at url: URL, completionHandler handler: @escaping (Error?) -> Void) {
         guard let file = Preview(url: url, handler: handler) else { return }
        file.run(web: self.webView)
    }
}
