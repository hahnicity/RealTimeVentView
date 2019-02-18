//
//  AlertModel.swift
//  RealTimeVentView
//
//  Created by user149673 on 2/13/19.
//  Copyright © 2019 CCIL. All rights reserved.
//

import Foundation

class AlertModel {
    var alertDTA: Bool
    var thresholdDTA: Int
    var alertBSA: Bool
    var thresholdBSA: Int
    var json: [String: Any] {
        get {
            return ["alertDTA": alertDTA, "thresholdDTA": thresholdDTA, "alertBSA": alertBSA, "thresholdBSA": thresholdBSA]
        }
    }
    
    init() {
        let setting = Storage.defaultAlert
        alertDTA = setting["alertDTA"] as! Bool
        thresholdDTA = setting["thresholdDTA"] as! Int
        alertBSA = setting["alertBSA"] as! Bool
        thresholdBSA = setting["thresholdBSA"] as! Int
    }
    
    init(withAlertDTA alertDTA: Bool, thresholdDTA: Int, alertBSA: Bool, thresholdBSA: Int) {
        self.alertDTA = alertDTA
        self.thresholdDTA = thresholdDTA
        self.alertBSA = alertBSA
        self.thresholdBSA = thresholdBSA
    }
    
    convenience init(at index: Int) {
        let alert = Storage.alerts[index]
        guard let adta = alert["alertDTA"] as? Bool, let tdta = alert["thresholdDTA"] as? Int, let absa = alert["alertBSA"] as? Bool, let tbsa = alert["thresholdBSA"] as? Int else {
            self.init()
            return
        }
        self.init(withAlertDTA: adta, thresholdDTA: tdta, alertBSA: absa, thresholdBSA: tbsa)
    }
    
    func store(for patient: PatientModel, completion: @escaping CompletionAPI) {
        Storage.alerts.append(["alertDTA": alertDTA, "thresholdDTA": thresholdDTA, "alertBSA": alertBSA, "thresholdBSA": thresholdBSA])
        ServerModel.shared.setAlertSettings(forPatient: patient.name, alertDTA: alertDTA, thresholdDTA: thresholdDTA, alertBSA: alertBSA, thresholdBSA: thresholdBSA, completion: completion)
    }
    
    func update(for patient: PatientModel, at index: Int, completion: @escaping CompletionAPI) {
        Storage.alerts[index] = self.json
        ServerModel.shared.setAlertSettings(forPatient: patient.name, alertDTA: alertDTA, thresholdDTA: thresholdDTA, alertBSA: alertBSA, thresholdBSA: thresholdBSA, completion: completion)
    }
}
