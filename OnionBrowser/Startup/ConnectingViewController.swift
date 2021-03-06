//
//  ConnectingViewController.swift
//  OnionBrowser2
//
//  Created by Benjamin Erhart on 10.01.20.
//  Copyright (c) 2012-2020, Tigas Ventures, LLC (Mike Tigas)
//
//  This file is part of Onion Browser. See LICENSE file for redistribution terms.
//

import UIKit

class ConnectingViewController: UIViewController, OnionManagerDelegate {

	class func start(_ showSecurityLevelsInfo: Bool = false) {
		let appDelegate = AppDelegate.shared

		if appDelegate?.browsingUi == nil {
			appDelegate?.browsingUi = BrowsingViewController()
		}

		appDelegate?.show(appDelegate?.browsingUi) { _ in
			TabSecurity.restore()

			appDelegate?.browsingUi?.becomesVisible()

			if showSecurityLevelsInfo {
				appDelegate?.browsingUi?.addNewTab(URL.aboutSecurityLevels)
			}
		}
	}


	@IBOutlet weak var titleLb: UILabel! {
		didSet {
			titleLb.text = NSLocalizedString("Connecting to Tor", comment: "")
		}
	}

	@IBOutlet weak var bridgeConfBt: UIButton!
	@IBOutlet weak var progress: UIProgressView! {
		didSet {
			progress.isHidden = true
		}
	}

	@IBOutlet weak var image: UIImageView!
	@IBOutlet weak var claimLb: UILabel!

	@IBOutlet weak var nextBt: UIButton! {
		didSet {
			nextBt.isHidden = true
		}
	}

	/**
	If set to true, will immediately jump to `browsingUi` after successful connect.
	*/
	var autoClose = false

	private var lastClaim: Int?

	private var refresh: Timer?

	private static let claims = [
		[
			"text": NSLocalizedString("__CLAIM_1__", comment: ""),
			"text_color": "white",
			"background_color": "group_bg",
			"image": "group",
		],
		[
			"text": NSLocalizedString("__CLAIM_2__", comment: ""),
			"text_color": "black",
			"background_color": "people_bg",
			"image": "people",
		],
		[
			"text": NSLocalizedString("__CLAIM_3__", comment: ""),
			"text_color": "white",
			"background_color": "facebook_bg",
			"image": "facebook",
		],
		[
			"text": NSLocalizedString("__CLAIM_4__", comment: ""),
			"text_color": "white",
			"background_color": "activist_bg",
			"image": "activist",
		],
		[
			"text": NSLocalizedString("__CLAIM_5__", comment: ""),
			"text_color": "white",
			"background_color": "blogger_bg",
			"image": "blogger",
		],
		[
			"text": NSLocalizedString("__CLAIM_6__", comment: ""),
			"text_color": "black",
			"background_color": "journalist_bg",
			"image": "journalist",
		],
		[
			"text": NSLocalizedString("__CLAIM_7__", comment: ""),
			"text_color": "black",
			"background_color": "business_bg",
			"image": "business",
		],
		[
			"text": NSLocalizedString("__CLAIM_8__", comment: ""),
			"text_color": "black",
			"background_color": "worker_bg",
			"image": "worker",
		],
	]

	override func viewDidLoad() {
		super.viewDidLoad()

		OnionManager.shared.setBridgeConfiguration(bridgesType: Settings.currentlyUsedBridges,
												   customBridges: Settings.customBridges)

		OnionManager.shared.startTor(delegate: self)
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)

		showClaim(nil)
		refresh = Timer.scheduledTimer(timeInterval: 3, target: self,
									   selector: #selector(showClaim), userInfo: nil, repeats: true)
	}

	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)

		refresh?.invalidate()
		refresh = nil
	}


	// MARK: OnionManagerDelegate

	func torConnProgress(_ progress: Int) {
		DispatchQueue.main.async {
			self.progress.progress = Float(progress) / 100
			self.progress.isHidden = false
		}
	}

	func torConnFinished() {
		DispatchQueue.main.async {
			Bookmark.firstRunSetup()

			if self.autoClose {
				return ConnectingViewController.start()
			}

			self.refresh?.invalidate()
			self.refresh = nil

			self.titleLb.text = NSLocalizedString("Connected!", comment: "")
			self.bridgeConfBt.isHidden = true
			self.bridgeConfBt.widthAnchor.constraint(equalToConstant: 0).isActive = true
			self.progress.isHidden = true
			self.claimLb.isHidden = true

			self.nextBt.setTitle(NSLocalizedString("Next", comment: ""))
			self.nextBt.isHidden = false
		}
	}

	func torConnError() {
		AppDelegate.shared?.show(ErrorViewController())
	}


	// MARK: Actions

	@IBAction func next() {
		AppDelegate.shared?.show(InitSecurityLevelViewController())
	}

    @IBAction func bridgeSettings() {
		BridgeConfViewController.present(from: self)
    }
    
	// MARK: Private methods

	@objc private func showClaim(_ timer: Timer?) {
		var nextClaim: Int

// FOR DEBUGGING: Show all in a row.
//		if lastClaim == nil || lastClaim! >= ConnectingViewController.claims.count - 1 {
//			nextClaim = 0
//		}
//		else {
//			nextClaim = lastClaim! + 1
//		}

		repeat {
			nextClaim = Int(arc4random_uniform(UInt32(ConnectingViewController.claims.count)))
		} while nextClaim == lastClaim

		lastClaim = nextClaim

		let data = ConnectingViewController.claims[nextClaim]

		claimLb.text = data["text"]
		claimLb.textColor = data["text_color"] == "white" ? .white : .black
		view.backgroundColor = UIColor(named: data["background_color"]!)
		image.image = UIImage(named: data["image"]!)
	}
}
