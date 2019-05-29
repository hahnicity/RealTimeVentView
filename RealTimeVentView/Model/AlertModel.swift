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
    var alertBS: AsynchronyAlertModel
    var alertDT: AsynchronyAlertModel
    var alertTV: AsynchronyAlertModel
    
    var json: [String: Any] {
        get {
            var json = alertBS.json.merging(alertDT.json) { a, b in a }.merging(alertTV.json) { a, b in a }
            json["notification"] = notification
            return json
        }
    }
    
    init() {
        self.notification = Storage.defaultAlert["notification"] as! Bool
        self.alertBS = AsynchronyAlertModel(forType: .bsa)
        self.alertDT = AsynchronyAlertModel(forType: .dta)
        self.alertTV = AsynchronyAlertModel(forType: .tvv)
    }
    
    init(withJSON json: [String: Any]) {
        self.notification = json["notification"] as! Bool
        self.alertBS = AsynchronyAlertModel(forType: .bsa, withJSON: json)
        self.alertDT = AsynchronyAlertModel(forType: .dta, withJSON: json)
        self.alertTV = AsynchronyAlertModel(forType: .tvv, withJSON: json)
    }
    
    convenience init(at index: Int) {
        self.init(withJSON: Storage.alerts[index])
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

enum AsyncType: Int {
    case bsa = 0
    case dta = 1
    case tvv = 2
    
    var string: String {
        get {
            switch self {
            case .bsa: return "BSA"
            case .dta: return "DTA"
            case .tvv: return "TVV"
            }
        }
    }
    
    var packetString: String {
        get {
            switch self {
            case .bsa: return "bsa"
            case .dta: return "dta"
            case .tvv: return "tvv"
            }
        }
    }
}

class AsynchronyAlertModel {
    var type: AsyncType
    var alert: Bool
    var thresholdFrequency: Int
    var timeFrame: Int
    var json: [String: Any] {
        get {
            return ["alert_for_\(type.packetString)": alert, "\(type.packetString)_alert_freq": thresholdFrequency, "minutes_between_alerts": timeFrame]
        }
    }
    
    init(forType type: AsyncType) {
        self.type = type
        self.alert = Storage.defaultAlert["alert_for_\(type.packetString)"] as! Bool
        self.thresholdFrequency = Storage.defaultAlert["\(type.packetString)_alert_freq"] as! Int
        self.timeFrame = Storage.defaultAlert["minutes_between_alerts"] as! Int
    }
    
    init(forType type: AsyncType, withJSON json: [String: Any]) {
        self.type = type
        self.alert = json["alert_for_\(type.packetString)"] as! Bool
        self.thresholdFrequency = json["\(type.packetString)_alert_freq"] as! Int
        self.timeFrame = json["minutes_between_alerts"] as! Int
    }
    
    init(forType type: AsyncType, setTo alert: Bool, withThresholdFrequencyOf thresholdFrequency: Int, withinTimeFrame timeFrame: Int) {
        self.type = type
        self.alert = alert
        self.thresholdFrequency = thresholdFrequency
        self.timeFrame = timeFrame
    }
    
    init(forType type: AsyncType, setTo alert: Bool, withThresholdFrequencyOf thresholdFrequency: Int) {
        self.type = type
        self.alert = alert
        self.thresholdFrequency = thresholdFrequency
        self.timeFrame = 0
    }
}
