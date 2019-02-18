//
//  Storage.swift
//  RealTimeVentView
//
//  Created by user149673 on 2/17/19.
//  Copyright © 2019 CCIL. All rights reserved.
//

import Foundation

class Storage {
    static var enrolledName: [String] {
        get {
            return UserDefaults.standard.array(forKey: "enrolledName") as? [String] ?? []
        }
        set(e) {
            UserDefaults.standard.set(e, forKey: "enrolledName")
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
    
    static var defaultAlertBSA: Bool {
        get {
            return UserDefaults.standard.bool(forKey: "defaultAlertBSA")
        }
        set(defaultAlertBSA) {
            UserDefaults.standard.set(defaultAlertBSA, forKey: "defaultAlertBSA")
        }
    }
    
    static var alertBSA: [Bool] {
        get {
            return UserDefaults.standard.array(forKey: "alertBSA") as? [Bool] ?? []
        }
        set(alertBSA) {
            UserDefaults.standard.set(alertBSA, forKey: "alertBSA")
        }
    }
    
    static var defaultThresholdBSA: Int {
        get {
            return UserDefaults.standard.integer(forKey: "defaultThresholdBSA")
        }
        set(defaultThresholdBSA) {
            UserDefaults.standard.set(defaultThresholdBSA, forKey: "defaultThresholdBSA")
        }
    }
    
    static var thresholdBSA: [Int] {
        get {
            return UserDefaults.standard.array(forKey: "thresholdBSA") as? [Int] ?? []
        }
        set(thresholdBSA) {
            UserDefaults.standard.set(thresholdBSA, forKey: "thresholdBSA")
        }
    }
    
    static var defaultAlertDTA: Bool {
        get {
            return UserDefaults.standard.bool(forKey: "defaultAlertDTA")
        }
        set(defaultAlertDTA) {
            UserDefaults.standard.set(defaultAlertDTA, forKey: "defaultAlertDTA")
        }
    }
    
    static var alertDTA: [Bool] {
        get {
            return UserDefaults.standard.array(forKey: "alertDTA") as? [Bool] ?? []
        }
        set(alertDTA) {
            UserDefaults.standard.set(alertDTA, forKey: "alertDTA")
        }
    }
    
    static var defaultThresholdDTA: Int {
        get {
            return UserDefaults.standard.integer(forKey: "defaultThresholdDTA")
        }
        set(defaultThresholdDTA) {
            UserDefaults.standard.set(defaultThresholdDTA, forKey: "defaultThresholdDTA")
        }
    }
    
    static var thresholdDTA: [Int] {
        get {
            return UserDefaults.standard.array(forKey: "thresholdDTA") as? [Int] ?? []
        }
        set(thresholdDTA) {
            UserDefaults.standard.set(thresholdDTA, forKey: "thresholdDTA")
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
            return UserDefaults.standard.dictionary(forKey: "defaultAlert") ?? ["alertDTA": true, "thresholdDTA": 20, "alertBSA": true, "thresholdBSA": 20]
        }
        set(defaultAlert) {
            UserDefaults.standard.set(defaultAlert, forKey: "defaultAlert")
        }
    }
}
