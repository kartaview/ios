//
//  SummaryViewController.swift
//  OpenStreetView
//
//  Created by Bogdan Sala on 16/01/2017.
//  Copyright © 2017 Bogdan Sala. All rights reserved.
//

import UIKit

class SummaryViewController: UIViewController {
    
                    var sequence: OSVSequence?
          public    var willDissmiss: (()->Void)?

    @IBOutlet weak  var congratsTitle: UILabel!

    @IBOutlet weak  var estimatedPointsLabel: UILabel!
    @IBOutlet weak  var estimatedPointsTitle: UILabel!
    
    @IBOutlet weak  var diskSizeTitle: UILabel!
    @IBOutlet weak  var diskSizeLabel: UILabel!
    
    @IBOutlet weak  var distanceCoveredTitle: UILabel!
    @IBOutlet weak  var distanceCoveredLabel: UILabel!
    
    @IBOutlet weak  var imagesTakenTitle: UILabel!
    @IBOutlet weak  var imagesTakenLabel: UILabel!
    
    @IBOutlet weak  var okButton: UIButton!
 
    override func viewDidLoad() {
        super.viewDidLoad()
        
        congratsTitle.text = NSLocalizedString("Well done!", comment:"")
        estimatedPointsTitle.attributedText = NSAttributedString.combineString("Points ", withSize:32, color:UIColor.init(hex:0x6e707b), fontName:"HelveticaNeue", with:"(estimated)", withSize:17, color:UIColor.init(hex:0x6e707b), fontName: "HelveticaNeue");
 
        if let estimatePoints = sequence?.points {
            estimatedPointsLabel.text = String(estimatePoints)
        } else {
            estimatedPointsLabel.text = "-"
        }

        diskSizeTitle.text = NSLocalizedString("Disk size", comment: "");
        distanceCoveredLabel.text = "-"
        DispatchQueue.main.async {
            self.diskSizeLabel.text = OSVUtils.memoryFormatter(OSVSyncController.sizeOnDisk(for: self.sequence))
        }
        distanceCoveredTitle.text = NSLocalizedString("Distance", comment: "")
        if let distance = sequence?.length {
            distanceCoveredLabel.text = OSVUtils.metricDistanceFormatter(Int(distance))
        } else {
            distanceCoveredLabel.text = "-"
        }
        
        imagesTakenTitle.text = NSLocalizedString("Photos", comment: "")
        if let count = sequence?.photos.count {
            imagesTakenLabel.text = String(count)
        } else {
            imagesTakenLabel.text = "-"
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if let callback = self.willDissmiss {
            callback()
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    @IBAction func didTapOkButton(_ sender: Any) {
        self.dismiss(animated: true, completion: {
            
        });
    }
}
