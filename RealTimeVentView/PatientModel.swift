//
//  PatientModel.swift
//  RealTimeVentView
//
//  Created by Tony Woo on 1/30/19.
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

class PatientModel {
    var name: String
    var age: Int
    var sex: String
    var height: Int
    
    var rpi: String {
        get {
            let regex = try! NSRegularExpression(pattern: "rpi[0-9]+$", options: [.anchorsMatchLines, .caseInsensitive])
            if let range = regex.firstMatch(in: name, options: [], range: NSRange(location: 0, length: name.count))?.range {
                return (name as NSString).substring(with: range)
            }
            return ""
        }
    }
    
    var json: [[String: Any]] = []
    var flow: [Double] = []
    var pressure: [Double] = []
    var breathIndex: [Int] = []
    
    init() {
        self.name = ""
        self.age = 0
        self.sex = ""
        self.height = 0
    }
    
    init(withName name: String, age: Int, sex: String, height: Int) {
        self.name = name
        self.age = age
        self.sex = sex
        self.height = height
    }
    
    init?(at index: Int) {
        let patient = Storage.patients[index]
        guard let name = patient["name"], let age_str = patient["age"], let age = Int(age_str), let sex = patient["sex"], let height_str = patient["height"], let height = Int(height_str) else {
            return nil
        }
        self.name = name
        self.age = age
        self.sex = sex
        self.height = height
    }
    
    func store() {
        Storage.patients.append(["name": name, "age": "\(age)", "sex": sex, "height": "\(height)"])
    }
    
    func getPatientData() -> [[String: Any]]? {
        let file = name == "Patient A" ? "sample" : "sample2"
        if let json = getJson(Named: file) {
            return json
        }
        return nil
    }
    
    func getJson(Named filename: String) -> [[String: Any]]? {
        if let url = Bundle.main.url(forResource: filename, withExtension: "json") {
            do {
                let data = try Data(contentsOf: url)
                let object = try JSONSerialization.jsonObject(with: data)
                if let json = object as? [[String: Any]] {
                    self.json = json
                    return json
                }
            } catch {
                print("\(error)")
            }
        }
        return nil
    }
    
    func getAllData(ofType field: String) -> [Double] {
        guard let json = getPatientData() else {
            return []
        }
        var data: [Double] = []
        for breath in json {
            guard let entity = (breath["breath_meta"] as? [String: Any])?[field] as? Double else {
                return []
            }
            data.append(entity)
        }
        
        return data
    }
    
    func retrieveFlowAndPressure() {
        if flow.count == 0 && pressure.count == 0 {
            guard let json = getPatientData() else {
                return
            }
            (flow, pressure, breathIndex) = parseJson(from: json)
        }
    }
    
    func addData(from json: [[String: Any]]) -> ([Double], [Double]) {
        let (flowData, pressureData, breathIn) = parseJson(from: json)
        flow = flowData + flow
        pressure = pressureData + pressure
        breathIndex = breathIn + breathIndex.map({ $0 + json.count })
        
        return (flowData, pressureData)
    }
    
    func parseJson(from json: [[String: Any]]) -> ([Double], [Double], [Int]) {
        var flowData: [Double] = [], pressureData: [Double] = [], breathIn: [Int] = []
        for (index, breath) in json.enumerated() {
            guard let temp = breath["vwd"] as? [String: [Double]], let flowEntity = temp["flow"], let pressureEntity = temp["pressure"] else {
                return ([], [], [])
            }
            flowData += flowEntity
            pressureData += pressureEntity
            breathIn += Array<Int>(repeating: index, count: flowEntity.count)
        }
        self.json += json
        return (flowData, pressureData, breathIn)
    }
}
