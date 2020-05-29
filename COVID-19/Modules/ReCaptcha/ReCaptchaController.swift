// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  ReCaptchaController.swift
//  STOP-COVID
//
//  Created by Lunabee Studio / Date - 18/05/2020 - for the STOP-COVID project.
//


import UIKit
import WebKit

final class ReCaptchaController: UIViewController, WKNavigationDelegate {
    
    let containerView: UIView = UIView()
    private var mainView: UIView = UIView()
    private var mainStackView: UIStackView = UIStackView()
    private var cancelButton: UIButton!
    private weak var webView: WKWebView?
    
    private let defaultRecaptchaSize: CGSize = CGSize(width: 300.0, height: 480.0)
    private let dismissBlock: () -> ()
    
    init(dismissBlock: @escaping () -> ()) {
        self.dismissBlock = dismissBlock
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("Must use standard init() method.")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
        configureWebView()
    }
    
    deinit {
        print("\(type(of: self)) deallocated")
        webView?.scrollView.delegate = nil
    }
    
    func setupWebView(_ webView: WKWebView) {
        self.webView = webView
    }
    
    func present(on viewController: UIViewController) {
        setInitialPosition()
        viewController.present(self, animated: false, completion: nil)
    }
    
    func dismiss() {
        UIView.animate(withDuration: 0.3, animations: {
            self.setInitialPosition()
        }) { _ in
            self.dismissBlock()
            self.dismiss(animated: false, completion: nil)
        }
    }
    
    private func initUI() {
        view.backgroundColor = .clear
        mainStackView.axis = .vertical
        mainStackView.distribution = .fill
        mainStackView.alignment = .fill
        mainView.layer.cornerRadius = 10.0
        mainView.layer.masksToBounds = true
        mainView.clipsToBounds = true
        mainView.backgroundColor = .white
        mainView.addConstrainedSubview(mainStackView)
        view.addCenteredSubview(mainView)
        
        cancelButton = UIButton(type: .system)
        cancelButton.setTitle("common.cancel".localized, for: .normal)
        cancelButton.tintColor = Asset.Colors.tint.color
        cancelButton.titleLabel?.font = Appearance.Button.font
        cancelButton.addTarget(self, action: #selector(cancelButtonPressed), for: .touchUpInside)
        cancelButton.heightAnchor.constraint(equalToConstant: 50.0).isActive = true
        mainStackView.addArrangedSubview(cancelButton)
    }
    
    private func configureWebView() {
        guard let webView = webView else { return }
        webView.backgroundColor = .clear
        webView.scrollView.showsVerticalScrollIndicator = false
        webView.scrollView.showsHorizontalScrollIndicator = false
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.isPagingEnabled = false
        webView.navigationDelegate = self
        fetchWebViewComponentSize(webView: webView) { size in
            self.setupSize(size ?? self.defaultRecaptchaSize)
        }
    }
    
    private func fetchWebViewComponentSize(webView: WKWebView, completion: @escaping (_ size: CGSize?) -> ()) {
        // Find iFrame with its name.
        webView.evaluateJavaScript("""
            var meta = document.createElement('meta');
            meta.name = 'viewport';
            meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
            var head = document.getElementsByTagName('head')[0];
            head.appendChild(meta);
            
            const width = document.getElementsByTagName('iframe')[2].getBoundingClientRect().width;
            const height = document.getElementsByTagName('iframe')[2].getBoundingClientRect().height;
            width.toString() + "|" + height.toString()
        """, completionHandler: { size, error in
            guard let size = size as? String else {
                completion(nil)
                return
            }
            let components: [String] = size.components(separatedBy: "|")
            guard components.count == 2 else {
                completion(nil)
                return
            }
            guard let width = Double(components.first ?? ""), let height = Double(components.last ?? "") else {
                completion(nil)
                return
            }
            completion(CGSize(width: width, height: height))
        })
    }
    
    private func setupSize(_ size: CGSize) {
        mainStackView.insertArrangedSubview(containerView, at: 0)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.widthAnchor.constraint(equalToConstant: size.width).isActive = true
        containerView.heightAnchor.constraint(equalToConstant: size.height).isActive = true
        if let webView = webView {
            webView.translatesAutoresizingMaskIntoConstraints = false
            containerView.addConstrainedSubview(webView)
        }
        view.layoutSubviews()
        webView?.scrollView.contentOffset.y = 20.0
        makeContentAppearing()
    }
    
    private func setInitialPosition() {
        view.backgroundColor = .clear
        mainView.alpha = 0.0
        mainView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
    }
    
    private func makeContentAppearing() {
        UIView.animate(withDuration: 0.3) {
            self.view.backgroundColor = UIColor.black.withAlphaComponent(0.8)
            self.mainView.alpha = 1.0
            self.mainView.transform = .identity
        }
    }
    
    @objc private func cancelButtonPressed() {
        dismiss()
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        print("☠️☠️☠️")
        if let host = navigationAction.request.url?.host {
            if host == "www.google.com" {
                decisionHandler(.allow)
                return
            }
        }
        decisionHandler(.cancel)
    }
    
}
