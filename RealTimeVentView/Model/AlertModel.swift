//
//  AlertModel.swift
//  RealTimeVentView
//
//  Created by user149673 on 2/13/19.
//  Copyright © 2019 CCIL. All rights reserved.
//

import Foundation

class AlertModel {
    var notification: Bool
    var alertDTA: Bool
    var thresholdDTA: Int
    var alertBSA: Bool
    var thresholdBSA: Int
    var alertTVV: Bool
    var thresholdTVV: Int
    var json: [String: Any] {
        get {
            return ["notification": notification, "alertDTA": alertDTA, "thresholdDTA": thresholdDTA, "alertBSA": alertBSA, "thresholdBSA": thresholdBSA, "alertTVV": alertTVV, "thresholdTVV": thresholdTVV]
        }
    }
    
    init() {
        let setting = Storage.defaultAlert
        notification = setting["notification"] as! Bool
        alertDTA = setting["alertDTA"] as! Bool
        thresholdDTA = setting["thresholdDTA"] as! Int
        alertBSA = setting["alertBSA"] as! Bool
        thresholdBSA = setting["thresholdBSA"] as! Int
        alertTVV = setting["alertTVV"] as! Bool
        thresholdTVV = setting["thresholdTVV"] as! Int
    }
    
    init(withAlertDTA alertDTA: Bool, thresholdDTA: Int, alertBSA: Bool, thresholdBSA: Int, alertTVV: Bool, thresholdTVV: Int, notification: Bool) {
        self.alertDTA = alertDTA
        self.thresholdDTA = thresholdDTA
        self.alertBSA = alertBSA
        self.thresholdBSA = thresholdBSA
        self.alertTVV = alertTVV
        self.thresholdTVV = thresholdTVV
        self.notification = notification
    }
    
    convenience init(at index: Int) {
        let alert = Storage.alerts[index]
        guard let adta = alert["alertDTA"] as? Bool, let tdta = alert["thresholdDTA"] as? Int, let absa = alert["alertBSA"] as? Bool, let tbsa = alert["thresholdBSA"] as? Int, let atvv = alert["alertTVV"] as? Bool, let ttvv = alert["thresholdTVV"] as? Int, let n = alert["notification"] as? Bool else {
            self.init()
            return
        }
        self.init(withAlertDTA: adta, thresholdDTA: tdta, alertBSA: absa, thresholdBSA: tbsa, alertTVV: atvv, thresholdTVV: ttvv, notification: n)
    }
    
    func store(for patient: PatientModel, completion: @escaping CompletionAPI) {
        Storage.alerts.append(self.json)
        if notification {
            ServerModel.shared.setAlertSettings(for: patient, to: self, completion: completion)
        }
        else {
            ServerModel.shared.removeAlertSettings(for: patient, completion: completion)
        }
    }
    
    func update(for patient: PatientModel, at index: Int, completion: @escaping CompletionAPI) {
        Storage.alerts[index] = self.json
        if notification {
            ServerModel.shared.setAlertSettings(for: patient, to: self, completion: completion)
        }
        else {
            ServerModel.shared.removeAlertSettings(for: patient, completion: completion)
        }
    }
}
