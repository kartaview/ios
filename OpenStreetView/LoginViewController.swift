//
//  LoginViewController.swift
//  OpenStreetView
//
//  Created by Bogdan Sala on 22/02/2017.
//  Copyright © 2017 Bogdan Sala. All rights reserved.
//

import UIKit
import FBSDKLoginKit

class LoginViewController: UIViewController, GIDSignInUIDelegate {

	
	@IBOutlet weak var titleButton: UIButton!
	
    override func viewDidLoad() {
        super.viewDidLoad()
		titleButton.setTitle(NSLocalizedString("Login", comment:""), for: .normal)
	}

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
	
	@IBAction func didTapFacebookButton(_ sender: Any) {
		let login = FBSDKLoginManager()
		login.logIn(withReadPermissions: nil, from: nil) { (result, error) in
			if error == nil {
				
				if((FBSDKAccessToken.current()) != nil) {
					FBSDKProfile.loadCurrentProfile(completion: { (profile, error) in
						if error == nil {
							NotificationCenter.default.post(name: Notification.Name("kOSVDidSigninRequest"),
															object: nil,
							                                userInfo: ["success":true])

							if let navController = self.navigationController {
								navController.popViewController(animated:true)
							}

							if let prof = FBSDKProfile.current() {
								NotificationCenter.default.post(name: Notification.Name("kOSVFacebookSignIn"),
																object: nil,
																userInfo: ["user":prof])

							}
						}
					})
				}
			} else {
				NSLog("does not log in")
			}
		}
	}
	
	@IBAction func didTapGoogleButton(_ sender: Any) {
		GIDSignIn.sharedInstance().uiDelegate = self
		GIDSignIn.sharedInstance().signIn()
	}
	
	@IBAction func didTapOSMButton(_ sender: Any) {
		if !OSVSyncController.sharedInstance().tracksController.userIsLoggedIn() {
			OSVSyncController.sharedInstance().tracksController.login(partial: { (error) in
				if error != nil {
					OSVSyncController.sharedInstance().tracksController.logout()
				} else {
					if let navController = self.navigationController {
						navController.popViewController(animated:true)
					}
				}
			}, andCompletion: { (error) in
				if error != nil {
					OSVSyncController.sharedInstance().tracksController.logout()
				} else {
					NotificationCenter.default.post(name: Notification.Name("kOSVDidSigninRequest"),
					object: nil,
					userInfo: ["success":true])
				}
			})
		}
	}
	
	@IBAction func didTapBackButton(_ sender: Any) {
		if let navController = self.navigationController {
			navController.popViewController(animated:true)
		}
	}
	
	func sign(_ signIn: GIDSignIn!, dismiss viewController: UIViewController!) {
		
		if let navController = self.navigationController {
			navController.popViewController(animated:true)
			viewController.dismiss(animated: true, completion: { 
				NotificationCenter.default.post(name: Notification.Name("kOSVDidSigninRequest"),
				                                object: nil,
				                                userInfo: ["success":true])

			});
		}
	}
}
