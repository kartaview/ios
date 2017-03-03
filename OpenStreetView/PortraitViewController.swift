//
//  PortraitViewController.swift
//  OpenStreetView
//
//  Created by Bogdan Sala on 25/01/2017.
//  Copyright © 2017 Bogdan Sala. All rights reserved.
//

import UIKit

class PortraitViewController: UIViewController,UIViewControllerTransitioningDelegate  {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
}
