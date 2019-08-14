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
    var alertBSA: AsynchronyAlertModel
    var alertDTA: AsynchronyAlertModel
    var alertTVV: AsynchronyAlertModel
    var alertRR: AsynchronyAlertModel
    var alertMV: AsynchronyAlertModel
    var alertTVI: AsynchronyAlertModel
    var alertMAW: AsynchronyAlertModel
    
    var json: [String: Any] {
        get {
            var json = alertBSA.json.merging(alertDTA.json) { a, b in a }.merging(alertTVV.json) { a, b in a }.merging(alertRR.json) { a, b in a }.merging(alertMV.json) {a, b in a}.merging(alertTVI.json) {a, b in a}.merging(alertMAW.json) {a, b in a}
            json["notification"] = notification
            return json
        }
    }
    
    init() {
        self.notification = Storage.defaultAlert["notification"] as! Bool
        self.alertBSA = AsynchronyAlertModel(forType: .bsa)
        self.alertDTA = AsynchronyAlertModel(forType: .dta)
        self.alertTVV = AsynchronyAlertModel(forType: .tvv)
        self.alertRR = AsynchronyAlertModel(forType: .rr)
        self.alertMV = AsynchronyAlertModel(forType: .mv)
        self.alertTVI = AsynchronyAlertModel(forType: .tvi)
        self.alertMAW = AsynchronyAlertModel(forType: .maw)
    }
    
    init(withJSON json: [String: Any]) {
        self.notification = json["notification"] as! Bool
        self.alertBSA = AsynchronyAlertModel(forType: .bsa, withJSON: json)
        self.alertDTA = AsynchronyAlertModel(forType: .dta, withJSON: json)
        self.alertTVV = AsynchronyAlertModel(forType: .tvv, withJSON: json)
        self.alertRR = AsynchronyAlertModel(forType: .rr, withJSON: json)
        self.alertTVI = AsynchronyAlertModel(forType: .tvi, withJSON: json)
        self.alertMV = AsynchronyAlertModel(forType: .mv, withJSON: json)
        self.alertMAW = AsynchronyAlertModel(forType: .maw, withJSON: json)
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
    case rr = 3
    case mv = 4
    case tvi = 5
    case maw = 6
    
    var string: String {
        get {
            switch self {
            case .bsa: return "BSA"
            case .dta: return "DTA"
            case .tvv: return "TVV"
            case .rr: return "RR"
            case .mv: return "MV"
            case .tvi: return "TVI"
            case .maw: return "MAW"
            }
        }
    }
    
    var packetString: String {
        get {
            switch self {
            case .bsa: return "bsa"
            case .dta: return "dta"
            case .tvv: return "tvv"
            case .rr: return "rr"
            case .mv: return "mv"
            case .tvi: return "tvi"
            case .maw: return "maw"
            }
        }
    }
}

class AsynchronyAlertModel {
    var type: AsyncType
    var alert: Bool
    var thresholdFrequency: Int
    var lowerThreshold: Int
    var alertDuration: Int?
    var timeFrame: Int
    var json: [String: Any] {
        get {
            var json: [String: Any] =  ["alert_for_\(type.packetString)": alert, "\(type.packetString)_alert_thresh": thresholdFrequency, "minutes_between_alerts": timeFrame]
            if self.type.packetString == "mv" || self.type.packetString == "rr" || self.type.packetString == "tvi" || self.type.packetString == "maw" {
                json["\(type.packetString)_alert_lower_thresh"] = lowerThreshold
            }
            if let alertDuration = alertDuration {
                json["\(type.packetString)_alert_duration"] = alertDuration
            }
            return json
        }
    }
    
    init(forType type: AsyncType) {
        self.type = type
        self.alert = Storage.defaultAlert["alert_for_\(type.packetString)"] as! Bool
        self.thresholdFrequency = Storage.defaultAlert["\(type.packetString)_alert_thresh"] as! Int
        self.timeFrame = Storage.defaultAlert["minutes_between_alerts"] as! Int
        self.alertDuration = Storage.defaultAlert["\(type.packetString)_alert_duration"] as? Int
        if type.packetString == "rr" || type.packetString == "mv" || type.packetString == "tvi" || type.packetString == "maw" {
            self.lowerThreshold = Storage.defaultAlert["\(type.packetString)_alert_lower_thresh"] as! Int
        } else {
            self.lowerThreshold = 0
        }
    }
    
    init(forType type: AsyncType, withJSON json: [String: Any]) {
        self.type = type
        self.alert = json["alert_for_\(type.packetString)"] as! Bool
        self.thresholdFrequency = json["\(type.packetString)_alert_thresh"] as! Int
        self.timeFrame = json["minutes_between_alerts"] as! Int
        self.alertDuration = json["\(type.packetString)_alert_duration"] as? Int
        if type.packetString == "rr" || type.packetString == "mv" || type.packetString == "tvi" || type.packetString == "maw" {
            self.lowerThreshold = json["\(type.packetString)_alert_lower_thresh"] as! Int
        } else {
            self.lowerThreshold = 0
        }
    }
    
    init(forType type: AsyncType, setTo alert: Bool, withThresholdFrequencyOf thresholdFrequency: Int, withLowerThresholFrequency rrLowerThreshold: Int, withAlertDurationOf alertDuration: Int? = nil, withinTimeFrame timeFrame: Int = 0) {
        self.type = type
        self.alert = alert
        self.thresholdFrequency = thresholdFrequency
        self.alertDuration = alertDuration
        self.timeFrame = timeFrame
        self.lowerThreshold = rrLowerThreshold
    }
    
}
