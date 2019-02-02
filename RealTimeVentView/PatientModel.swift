//
//  PatientModel.swift
//  RealTimeVentView
//
//  Created by Tony Woo on 1/30/19.
//  Copyright © 2019 CCIL. All rights reserved.
//

import Foundation

class Storage {
    static var enrolled: [String] {
        get {
            return UserDefaults.standard.array(forKey: "enrolled") as? [String] ?? []
        }
        set(e) {
            UserDefaults.standard.set(e, forKey: "enrolled")
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
}

class PatientModel {
    var name: String
    var json: [[String: Any]] = []
    var flow: [Double] = []
    var pressure: [Double] = []
    var breathIndex: [Int] = []
    
    init() {
        self.name = ""
    }
    
    init(withName name: String) {
        self.name = name
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
