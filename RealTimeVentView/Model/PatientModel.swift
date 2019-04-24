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
    
    var rpi: String    
    var json: [[String: Any]] = []
    var flow: [Double] = []
    var pressure: [Double] = []
    var breathIndex: [Int] = []
    var asynchrony: [String] = []
    var asynchronyIndex: [Int] = []
    var refDate: Date? = nil
    var offsets: [Double] = []
    var sizeOfLastLoad = 0
    
    init() {
        self.name = ""
        self.age = 0
        self.sex = ""
        self.height = 0
        self.rpi = ""
    }
    
    init(withName name: String, age: Int, sex: String, height: Int) {
        self.name = name
        self.age = age
        self.sex = sex
        self.height = height
        self.rpi = PatientModel.getDefaultRPi(forPatient: name)
    }
    
    init?(with json: [String: String]) {
        guard let name = json["name"], let age_str = json["age"], let age = Int(age_str), let sex = json["sex"], let height_str = json["height"], let height = Int(height_str), let rpi = json["rpi"] else {
            return nil
        }
        self.name = name
        self.age = age
        self.sex = sex
        self.height = height
        self.rpi = rpi
    }
    
    convenience init?(at index: Int) {
        self.init(with: Storage.patients[index])
    }
    
    static func searchPatient(named name: String) -> PatientModel {
        for patient in Storage.patients {
            if let patientName = patient["name"], name == patientName, let patient = PatientModel(with: patient) {
                return patient
            }
        }
        return PatientModel()
    }
    
    static func removePatient(at index: Int, completion: @escaping CompletionAPI) {
        ServerModel.shared.disassociatePatient(named: PatientModel(at: index)!.name) { (data, error) in
            switch((data, error)) {
            case(.some, .none):
                Storage.patients.remove(at: index)
                Storage.alerts.remove(at: index)
                completion(data, nil)
            case(.none, .some(let error)):
                completion(nil, error)
            default: ()
            }
        }
    }
    
    static func getDefaultRPi(forPatient name: String) -> String {
        let regex = try! NSRegularExpression(pattern: "[0-9]+$", options: [.anchorsMatchLines, .caseInsensitive])
        if let range = regex.firstMatch(in: name, options: [], range: NSRange(location: 0, length: name.count))?.range, let num = Int((name as NSString).substring(with: range)) {
            return "rpi\(num)"
        }
        return ""
    }
    
    func updateRPi(to rpi: String, at index: Int, completion: @escaping CompletionAPI) {
        ServerModel.shared.changeRPi(forPatient: name, to: rpi) { (data, error) in
            switch((data, error)) {
            case(.some, .none):
                self.rpi = rpi
                Storage.patients[index]["rpi"] = rpi
                completion(data, nil)
            case(.none, .some(let error)):
                completion(nil, error)
            default: ()
            }
        }
    }
    
    func store(completion: @escaping CompletionAPI) {
        Storage.patients.append(["name": name, "age": "\(age)", "sex": sex, "height": "\(height)", "rpi": rpi])
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
                    let (newFlow, newPressure, newIndex, newOffsets, newAsynchrony, newAsynchronyIndex) = self.parseBreathJSON(json)
                    self.flow = newFlow
                    self.pressure = newPressure
                    self.breathIndex = newIndex
                    self.json = json
                    self.offsets = newOffsets
                    self.asynchrony = newAsynchrony
                    self.asynchronyIndex = newAsynchronyIndex
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
        dateFormatter.dateFormat = SERVER_DATE_FORMAT
        dateFormatter.timeZone = TimeZone(abbreviation: SERVER_TIMEZONE)!

        //print((json[0]["breath_meta"] as? [String: Any])?["abs_bs"])
        guard json.count > 0, let first = json[0][PACKET_METADATA] as? [String: Any], let date = first[PACKET_TIMESTAMP] as? String, let lastDate = dateFormatter.date(from: date) else {
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
                    let (newFlow, newPressure, newIndex, newOffsets, newAsynchrony, newAsynchronyIndex) = self.parseBreathJSON(json)
                    self.flow = newFlow + self.flow
                    self.pressure = newPressure + self.pressure
                    self.breathIndex = newIndex + self.breathIndex
                    self.json = json + self.json
                    self.offsets = newOffsets + self.offsets
                    self.asynchrony = newAsynchrony + self.asynchrony
                    self.asynchronyIndex = newAsynchronyIndex + self.asynchronyIndex.map{ $0 + newOffsets.count }
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
        dateFormatter.dateFormat = SERVER_DATE_FORMAT
        dateFormatter.timeZone = TimeZone(abbreviation: SERVER_TIMEZONE)!

        var lastDate = Date(timeIntervalSinceNow: -TimeInterval(Storage.updateInterval))
        if json.count > 0 {
            guard let first = json[json.count - 1][PACKET_METADATA] as? [String: Any], let date = first[PACKET_TIMESTAMP] as? String, let l = dateFormatter.date(from: date) else {
                print("Error getting the last date")
                return
            }
            lastDate = l
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
                    let (newFlow, newPressure, newIndex, newOffsets, newAsynchrony, newAsynchronyIndex) = self.parseBreathJSON(json)
                    self.flow = self.flow + newFlow
                    self.pressure = self.pressure + newPressure
                    self.breathIndex = self.breathIndex + newIndex.map({ $0 + self.json.count })
                    self.json = self.json + json
                    self.asynchrony = self.asynchrony + newAsynchrony
                    self.asynchronyIndex = self.asynchronyIndex + newAsynchronyIndex.map{ $0 + self.offsets.count }
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
    
    func parseBreathJSON(_ json: [[String: Any]]) -> ([Double], [Double], [Int], [Double], [String], [Int]) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = SERVER_DATE_FORMAT
        dateFormatter.timeZone = TimeZone(abbreviation: SERVER_TIMEZONE)!

        if refDate == nil {
            if json.count > 0, let first = json[0][PACKET_METADATA] as? [String: Any], let date = first[PACKET_TIMESTAMP] as? String {
                refDate = dateFormatter.date(from: date)
            }
        }
        
        var flowData: [Double] = [], pressureData: [Double] = [], indexData: [Int] = [], offsets: [Double] = [], asynchrony: [String] = [], asynchronyIndex: [Int] = []
        for (index, breath) in json.enumerated() {
            if let temp = breath[PACKET_WAVE_DATA] as? [String: [Double]], let flowSet = temp["flow"], let pressureSet = temp["pressure"], let date = (breath["breath_meta"] as? [String: Any])?["abs_bs"] as? String, let classifications = breath["classifications"] as? [String: Int] {
                flowData += flowSet
                pressureData += pressureSet
                indexData += Array<Int>(repeating: index, count: flowSet.count)
                switch (classifications["bs_1or2"], classifications["dbl_4"], classifications["tvv"]) {
                case (1, _, _):
                    asynchrony.append("BSA")
                    asynchronyIndex.append(offsets.count + flowSet.count / 2)
                case (_, 1, _):
                    asynchrony.append("DTA")
                    asynchronyIndex.append(offsets.count + flowSet.count / 2)
                case (_, _, 1):
                    asynchrony.append("TVV")
                    asynchronyIndex.append(offsets.count + flowSet.count / 2)
                default: ()
                }
                let base = dateFormatter.date(from: date)!.timeIntervalSince(refDate!)
                // change sample rate around here
                if index < json.count - 1 {
                    if let nextDate = (json[index + 1]["breath_meta"] as? [String: Any])?["abs_bs"] as? String, let next = dateFormatter.date(from: nextDate) {
                        // if next.timeIntervalSince(refDate!) - base < PatientModel.SAMPLE_RATE * Double(flowSet.count) {
                            offsets += Array<Double>(sequence(first: base) { $0 + (next.timeIntervalSince(self.refDate!) - base) / Double(flowSet.count) }.prefix(flowSet.count))
                        // }
                        /*
                        else {
                            offsets += Array<Double>(stride(from: 0.0, to: Double(flowSet.count) * PatientModel.SAMPLE_RATE, by: PatientModel.SAMPLE_RATE)).map({ $0 + base })
                        }
                        */
                    }
                }
                else {
                    if self.json.count > 0, let nextDate = (self.json[0]["breath_meta"] as? [String: Any])?["abs_bs"] as? String, let next = dateFormatter.date(from: nextDate), next.timeIntervalSince(refDate!) > base {
                        print("\(next.timeIntervalSince(refDate!)) \(base)")
                        offsets += Array<Double>(sequence(first: base) { $0 + (next.timeIntervalSince(self.refDate!) - base) / Double(flowSet.count) }.prefix(flowSet.count))
                    }
                    else {
                        offsets += Array<Double>(sequence(first: base) { $0 + PatientModel.SAMPLE_RATE }.prefix(flowSet.count))
                    }
                }
                assert(offsets.count == flowData.count)
            }
        }
        return (flowData, pressureData, indexData, offsets, asynchrony, asynchronyIndex)
    }
    
    func loadBreaths(between startTime: Date, and endTime: Date, completion: @escaping CompletionUpdate) {
        ServerModel.shared.getBreaths(forPatient: name, startTime: startTime, endTime: endTime) { (data, error) in
            switch((data, error)) {
            case(.some(let data), .none):
                do {
                    let object = try JSONSerialization.jsonObject(with: data)
                    guard let json = object as? [[String: Any]] else {
                        print("Some error regarding breath json")
                        return
                    }
                    let (newFlow, newPressure, newIndex, newOffsets, newAsynchrony, newAsynchronyIndex) = self.parseBreathJSON(json)
                    self.flow = newFlow
                    self.pressure = newPressure
                    self.breathIndex = newIndex
                    self.json = json
                    self.offsets = newOffsets
                    self.asynchrony = newAsynchrony
                    self.asynchronyIndex = newAsynchronyIndex
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
    
    func loadJSON(completion: @escaping CompletionUpdate) {
        guard let json = getJson(Named: "sample3") else {
            return
        }
        print("Num: \(json.count)")
        let (newFlow, newPressure, newIndex, newOffsets, newAsynchrony, newAsynchronyIndex) = self.parseBreathJSON(json)
        print("Flows: \(newFlow.count)")
        print("Async: \(newAsynchrony.count)")
        self.flow = newFlow
        self.pressure = newPressure
        self.breathIndex = newIndex
        self.json = json
        self.offsets = newOffsets
        self.asynchrony = newAsynchrony
        self.asynchronyIndex = newAsynchronyIndex
        DispatchQueue.global(qos: .userInitiated).async {
            completion(newFlow, newPressure, newOffsets, nil)
        }
    }
    
    func loadPastJSON(completion: @escaping CompletionUpdate) {
        guard let json = getJson(Named: "sample") else {
            return
        }
        print("Num: \(json.count)")
        let (newFlow, newPressure, newIndex, newOffsets, newAsynchrony, newAsynchronyIndex) = self.parseBreathJSON(json)
        print("Flows: \(newFlow.count)")
        self.flow = newFlow + self.flow
        self.pressure = newPressure + self.pressure
        self.breathIndex = newIndex + self.breathIndex
        self.json = json + self.json
        self.offsets = newOffsets + self.offsets
        self.asynchrony = newAsynchrony + self.asynchrony
        self.asynchronyIndex = newAsynchronyIndex + self.asynchronyIndex
        DispatchQueue.global(qos: .userInitiated).async {
            completion(newFlow, newPressure, newOffsets, nil)
        }
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
        return json.compactMap { (breath) -> Double? in
            guard let entity = (breath["breath_meta"] as? [String: Any])?[field] as? Double else {
                return nil
            }
            return entity
        }
    }
    
    func getBreathID() -> [Int] {
        return json.compactMap({ (breath) -> Int? in
            guard let entity = (breath["breath_meta"] as? [String: Any])?["id"] as? Int else {
                return nil
            }
            return entity
        })
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
