////
////  ScoreHistory.swift
////  OpenStreetView
////
////  Created by Bogdan Sala on 22/12/2016.
////  Copyright © 2016 Bogdan Sala. All rights reserved.
////
//
//import Foundation
//
//@objc class ScoreHistory : NSObject {
//    fileprivate var scoreHistoryID : String
//
//    var localSequenceID : Int
//    var photosWithOBD : Int
//    var detectedSigns : Int
//    var multiplier : Int
//    var distance : Double
//    var coverage : Int
//    var photos : Int
//    var points : Int
//    
//    override convenience init() {
//        self.init(coverage:0, localSequenceID:0)
//    }
//    
//    init(coverage:Int, localSequenceID:Int) {
//        self.localSequenceID = localSequenceID
//        self.coverage = coverage
//        
//        self.photos = 0
//        self.points = 0
//        
//        self.scoreHistoryID = String(self.localSequenceID) + String(self.coverage)
//        self.photosWithOBD = 0
//        self.detectedSigns = 0
//        self.multiplier = 1;
//        self.distance = 0.0;
//        
//        super.init()
//    }
//}
//
//extension ScoreHistory {
//    
//    func toRealmObject() -> RLMScoreHistory {
//        let history                 = RLMScoreHistory();
//        history.scoreHistoryID      = self.scoreHistoryID;
//        history.localSequenceID     = self.localSequenceID;
//        history.coverage            = self.coverage;
//        history.photos              = self.photos;
//        history.photosWithOBD       = self.photosWithOBD;
//        history.detectedSigns       = self.detectedSigns;
//        
//        return history;
//    }
//    
//    class func fromRealmObject(historyObject:RLMScoreHistory) -> ScoreHistory {
//        let history                 = ScoreHistory();
//        history.scoreHistoryID      = historyObject.scoreHistoryID;
//        history.localSequenceID     = historyObject.localSequenceID;
//        history.coverage            = historyObject.coverage;
//        history.photos              = historyObject.photos;
//        history.photosWithOBD       = historyObject.photosWithOBD;
//        history.detectedSigns       = historyObject.detectedSigns;
//        
//        return history;
//
//    }
//}
