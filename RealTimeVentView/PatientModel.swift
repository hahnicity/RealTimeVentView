//
//  PatientModel.swift
//  RealTimeVentView
//
//  Created by Tony Woo on 1/30/19.
//  Copyright © 2019 CCIL. All rights reserved.
//

import Foundation



typealias CompletionUpdate = ([Double], [Double], [Double], Error?) -> ()

class PatientModel {
    var name: String
    var age: Int
    var sex: String
    var height: Int
    static let SAMPLE_RATE: Double = 0.02
    
    var rpi: String {
        get {
            let regex = try! NSRegularExpression(pattern: "[0-9]+$", options: [.anchorsMatchLines, .caseInsensitive])
            if let range = regex.firstMatch(in: name, options: [], range: NSRange(location: 0, length: name.count))?.range, let num = Int((name as NSString).substring(with: range)) {
                return "rpi\(num)"
            }
            return ""
        }
    }
    
    var json: [[String: Any]] = []
    var flow: [Double] = []
    var pressure: [Double] = []
    var breathIndex: [Int] = []
    var refDate: Date? = nil
    var offsets: [Double] = []
    var sizeOfLastLoad = 0
    
    init() {
        self.name = ""
        self.age = 0
        self.sex = ""
        self.height = 0
    }
    
    init(withName name: String) {
        self.name = name
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
    
    init?(with json: [String: String]) {
        guard let name = json["name"], let age_str = json["age"], let age = Int(age_str), let sex = json["sex"], let height_str = json["height"], let height = Int(height_str) else {
            return nil
        }
        self.name = name
        self.age = age
        self.sex = sex
        self.height = height
    }
    
    convenience init?(at index: Int) {
        self.init(with: Storage.patients[index])
    }
    
    
    func store(completion: @escaping CompletionAPI) {
        Storage.patients.append(["name": name, "age": "\(age)", "sex": sex, "height": "\(height)"])
        ServerModel.shared.enrollPatient(withName: name, rpi: rpi, height: height, sex: sex, age: age, completion: completion)
    }
    
    func loadBreaths(completion: @escaping CompletionUpdate) {
        print(Date())
        print(Date(timeIntervalSinceNow: TimeInterval(-60 * Storage.loadTimeFrame)))
        ServerModel.shared.getBreaths(forPatient: name, startTime: Date(timeIntervalSinceNow: TimeInterval(-60 * Storage.loadTimeFrame)), endTime: Date()) { (data, error) in
            switch((data, error)) {
            case(.some(let data), .none):
                do {
                    let object = try JSONSerialization.jsonObject(with: data)
                    guard let json = object as? [[String: Any]] else {
                        print("Some error regarding breath json")
                        return
                    }
                    let (newFlow, newPressure, newIndex, newOffsets) = self.parseBreathJSON(json)
                    self.flow = newFlow
                    self.pressure = newPressure
                    self.breathIndex = newIndex
                    self.json = json
                    self.offsets = newOffsets
                    completion(newFlow, newPressure, newOffsets, nil)
                } catch {
                    print("\(error)")
                }
            case(.none, .some(let error)):
                completion([], [], [], error)
            default: ()
            }
        }
    }
    
    func loadPastBreaths(completion: @escaping CompletionUpdate) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "E, d MMM yyyy HH:mm:ss zz"
        //print((json[0]["breath_meta"] as? [String: Any])?["abs_bs"])
        guard let first = json[0]["breath_meta"] as? [String: Any], let date = first["abs_bs"] as? String, let lastDate = dateFormatter.date(from: date) else {
            print("Error getting the last date")
            return
        }
        
        ServerModel.shared.getBreaths(forPatient: name, startTime: Date(timeInterval: TimeInterval(-60 * Storage.loadTimeFrame), since: lastDate), endTime: Date(timeInterval: -1, since: lastDate)) { (data, error) in
            switch((data, error)) {
            case(.some(let data), .none):
                do {
                    let object = try JSONSerialization.jsonObject(with: data)
                    guard let json = object as? [[String: Any]] else {
                        print("Some error regarding breath json")
                        return
                    }
                    let (newFlow, newPressure, newIndex, newOffsets) = self.parseBreathJSON(json)
                    self.flow = newFlow + self.flow
                    self.pressure = newPressure + self.pressure
                    self.breathIndex = newIndex + self.breathIndex
                    self.json = json + self.json
                    self.offsets = newOffsets + self.offsets
                    completion(newFlow, newPressure, newOffsets, nil)
                } catch {
                    print("\(error)")
                }
            case(.none, .some(let error)):
                completion([], [], [], error)
            default: ()
            }
        }
    }
    
    func loadNewBreaths(completion: @escaping CompletionUpdate) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "E, d MMM yyyy HH:mm:ss zz"
        guard let first = json[json.count - 1]["breath_meta"] as? [String: Any], let date = first["abs_bs"] as? String, let lastDate = dateFormatter.date(from: date) else {
            print("Error getting the last date")
            return
        }
        
        ServerModel.shared.getBreaths(forPatient: name, startTime: Date(timeInterval: 1, since: lastDate), endTime: Date()) { (data, error) in
            switch((data, error)) {
            case(.some(let data), .none):
                do {
                    let object = try JSONSerialization.jsonObject(with: data)
                    guard let json = object as? [[String: Any]] else {
                        print("Some error regarding breath json")
                        return
                    }
                    let (newFlow, newPressure, newIndex, newOffsets) = self.parseBreathJSON(json)
                    self.flow = self.flow + newFlow
                    self.pressure = self.pressure + newPressure
                    self.breathIndex = self.breathIndex + newIndex
                    self.json = self.json + json
                    self.offsets = self.offsets + newOffsets
                    completion(newFlow, newPressure, newOffsets, nil)
                } catch {
                    print("\(error)")
                }
            case(.none, .some(let error)):
                completion([], [], [], error)
            default: ()
            }
        }
    }
    
    func parseBreathJSON(_ json: [[String: Any]]) -> ([Double], [Double], [Int], [Double]) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "E, d MMM yyyy HH:mm:ss zz"
        if refDate == nil {
            if let first = json[0]["breath_meta"] as? [String: Any], let date = first["abs_bs"] as? String {
                refDate = dateFormatter.date(from: date)
            }
        }
        
        var flowData: [Double] = [], pressureData: [Double] = [], indexData: [Int] = [], offsets: [Double] = []
        for (index, breath) in json.enumerated() {
            if let temp = breath["vwd"] as? [String: [Double]], let flowSet = temp["flow"], let pressureSet = temp["pressure"], let date = (breath["breath_meta"] as? [String: Any])?["abs_bs"] as? String {
                flowData += flowSet
                pressureData += pressureSet
                indexData += Array<Int>(repeating: index, count: flowSet.count)
                let base = dateFormatter.date(from: date)!.timeIntervalSince(refDate!)
                offsets += Array<Double>(stride(from: 0.0, to: Double(flowSet.count) * PatientModel.SAMPLE_RATE, by: PatientModel.SAMPLE_RATE)).map({ $0 + base })
            }
        }
        return (flowData, pressureData, indexData, offsets)
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
        var data: [Double] = []
        for breath in json {
            guard let entity = (breath["breath_meta"] as? [String: Any])?[field] as? Double else {
                return []
            }
            data.append(entity)
        }
        
        return data
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
