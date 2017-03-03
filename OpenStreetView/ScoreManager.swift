//
//  ScoreManager.swift
//  OpenStreetView
//
//  Created by Bogdan Sala on 21/12/2016.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//

import Foundation

@objc class ScoreManager: NSObject {
    private static let coverageScore = [-1: 0.0, 0 : 10.0, 1 : 5.0, 2 : 5.0, 3 : 3.0, 4 : 3.0, 5 : 2.0, 6 : 2.0, 7 : 2.0, 8 : 2.0, 9 : 2.0, 10 : 1.0]
    private var localSequenceID : Int
    private var historyCoverage : Dictionary<Int, OSVScoreHistory>
    
    var score       : Double
    var multiplier  : Double

    override init() {
        self.localSequenceID = 0
        self.historyCoverage = Dictionary()
        
        self.score = 0
        self.multiplier = 1
    }
    
    func startHistorySession(forSequenceID:Int) -> Void {
        self.localSequenceID = forSequenceID
        self.resetMetrics()
    }
    
    func stopHistorySession() -> Void {
        self.resetMetrics()
    }
    
    func detectedRoadSign(onSegment:OSVPolyline) -> Void {
        let captCoverage = min(onSegment.coverage, 10)
        if let coverageHistory = self.historyCoverage[captCoverage] {
            coverageHistory.detectedSigns += 1;
        }
        
        self.score += 1;
    }
    
    func madePhoto(onSegment:OSVPolyline, withOBD:Bool) -> Void {
        
        let captCoverage = min(onSegment.coverage, 10)
        let coverageHistory = self.historyCoverage[captCoverage];
        coverageHistory?.photos += 1;
        coverageHistory?.photosWithOBD += withOBD ? 1 : 0;
        
        OSVSyncController.sharedInstance().tracksController.store(coverageHistory)
        
        if let photoScore = ScoreManager.coverageScore[captCoverage] {
            self.multiplier = withOBD ? photoScore * 2.0 : photoScore
        } else {
            self.multiplier = 1
        }
        
        self.score += self.multiplier
    }
    
    func madePhoto(withOBD:Bool) -> Void {
        if let coverageHistory = self.historyCoverage[-1] {
            coverageHistory.photos += 1;
            coverageHistory.photosWithOBD += withOBD ? 1 : 0;
            OSVSyncController.sharedInstance().tracksController.store(coverageHistory)
        }
        
        self.score += 0;
    }
    
    func updateMultiplier(onSegment:OSVPolyline, withOBD:Bool) -> Void {
        let captCoverage = min(onSegment.coverage, 10)
        
        if let locationScore = ScoreManager.coverageScore[captCoverage] {
            self.multiplier = withOBD ? locationScore * 2.0 : locationScore
        } else {
            self.multiplier = withOBD ? 1 * 2.0 : 1;
        }
    }
 
    func resetMetrics() -> Void {
        self.score = 0;
        
        self.historyCoverage = Dictionary();
        
        for coverage in -1...10 {
            let history = OSVScoreHistory(forCoverage:coverage, withLocalSequenceID:self.localSequenceID)
            if let photoScore = ScoreManager.coverageScore[coverage] {
                history.multiplier = photoScore
            }
            self.historyCoverage[coverage] = history
        }
    }
    
    class func scoreFor(coverage:Int) -> Double {
        if let photoScore = ScoreManager.coverageScore[coverage] {
            return photoScore
        }

        return 0.0;
    }
    
}
