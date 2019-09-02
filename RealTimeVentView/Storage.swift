//
//  Storage.swift
//  RealTimeVentView
//
//  Created by user149673 on 2/17/19.
//  Copyright © 2019 CCIL. All rights reserved.
//

import Foundation

class Storage {
    
    static var deviceToken: String {
        get {
            return UserDefaults.standard.string(forKey: "deviceToken") ?? ""
        }
        set(deviceToken) {
            UserDefaults.standard.set(deviceToken, forKey: "deviceToken")
        }
    }
    
    static var defaultNumBreaths: Int {
        get {
            return UserDefaults.standard.integer(forKey: "defaultNumBreaths")
        }
        set(dnb) {
            UserDefaults.standard.set(dnb, forKey: "defaultNumBreaths")
        }
    }
    
    static var updateInterval: Int {
        get {
            return UserDefaults.standard.integer(forKey: "updateInterval")
        }
        set(updateInterval) {
            UserDefaults.standard.set(updateInterval, forKey: "updateInterval")
        }
    }
    
    static var loadTimeFrame: Int {
        get {
            return UserDefaults.standard.integer(forKey: "loadTimeFrame")
        }
        set(updateInterval) {
            UserDefaults.standard.set(updateInterval, forKey: "loadTimeFrame")
        }
    }
    
    static var numFeedbackBreaths: Int {
        get {
            return UserDefaults.standard.integer(forKey: "numFeedbackBreaths")
        }
        set(numFeedbackBreaths) {
            UserDefaults.standard.set(numFeedbackBreaths, forKey: "numFeedbackBreaths")
        }
    }
    
    static var patients: [[String: String]] {
        get {
            return UserDefaults.standard.array(forKey: "patients") as? [[String: String]] ?? []
        }
        set(patients) {
            UserDefaults.standard.set(patients, forKey: "patients")
        }
    }
    
    static var alerts: [[String: Any]] {
        get {
            return UserDefaults.standard.array(forKey: "alerts") as? [[String: Any]] ?? []
        }
        set(alerts) {
            UserDefaults.standard.set(alerts, forKey: "alerts")
        }
    }
    
    static var defaultAlert: [String: Any] {
        get {
            return UserDefaults.standard.dictionary(forKey: "defaultAlert") ?? ["notification": true, "alert_for_dta": true, "dta_alert_thresh": 3, "dta_alert_time_frame": 5, "alert_for_bsa": true, "bsa_alert_thresh": 10 , "bsa_alert_time_frame": 5, "alert_for_tvv": true, "tvv_alert_thresh": 3, "tvv_alert_time_frame": 5, "alert_for_rr": true, "rr_alert_thresh": 3, "rr_alert_lower_thresh": 0, "rr_alert_time_frame": 5, "alert_for_tvi": true, "tvi_alert_thresh": 600, "tvi_alert_lower_thresh": 100, "tvi_alert_time_frame": 5, "alert_for_mv": true, "mv_alert_thresh": 40, "mv_alert_lower_thresh": 5, "mv_alert_time_frame": 5, "alert_for_maw": true, "maw_alert_thresh": 40, "maw_alert_lower_thresh": 5, "maw_alert_time_frame": 5, "minutes_between_alerts": 30]
        }
        set(defaultAlert) {
            UserDefaults.standard.set(defaultAlert, forKey: "defaultAlert")
        }
    }
}
