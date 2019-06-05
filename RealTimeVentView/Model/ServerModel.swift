//
//  ServerModel.swift
//  RealTimeVentView
//
//  Created by user149673 on 2/15/19.
//  Copyright © 2019 CCIL. All rights reserved.
//

import Foundation

typealias CompletionAPI = (Data?, Error?) -> ()

let SERVER_DATE_FORMAT = "yyyy-MM-dd HH:mm:ss.SSSSSS"
let SERVER_TIMEZONE = TimeZone(abbreviation: "GMT")!
let PACKET_METADATA = "breath_meta"
let PACKET_CLASSIFICATION = "classifications"
let PACKET_WAVE_DATA = "vwd"
let PACKET_TIMESTAMP = "abs_bs"
let PACKET_E_TIME = "e_time"
let PACKET_I_TIME = "i_time"
let PACKET_IE_RATIO = "ie_ratio"
let PACKET_PEEP = "peep"
let PACKET_TVE_TVI_RATIO = "tve_tvi_ratio"
let PACKET_TVE = "tve"
let PACKET_TVI = "tvi"
let PACKET_EP_AUC = "ep_auc"
let PACKET_IP_AUC = "ip_auc"
let PACKET_ID = "id"
let PACKET_RR = "inst_rr"
let PACKET_PIP = "pip"
let PACKET_BSA = "bs_1or2"
let PACKET_DTA = "dbl_4"
let PACKET_TVV = "tvv"
let PACKET_FLOW = "flow"
let PACKET_PRESSURE = "pressure"

// Luigi
let CLASSIFICATIONS_TO_PACKET_NAME = ["BSA": PACKET_BSA, "DTA": PACKET_DTA, "TVV": PACKET_TVV]

let BREATH_METADATA = ["E-Time", "I-Time", "I:E Ratio", "TVe", "TVi", "TVe/TVi", "epAUC", "ipAUC", "RR", "PEEP", "PIP"]
let METADATA_TO_PACKET_NAME = ["E-Time": PACKET_E_TIME, "I-Time": PACKET_I_TIME, "I:E Ratio": PACKET_IE_RATIO, "TVe": PACKET_TVE, "TVi": PACKET_TVI, "TVe/TVi": PACKET_TVE_TVI_RATIO, "epAUC": PACKET_EP_AUC, "ipAUC": PACKET_IP_AUC, "RR": PACKET_RR, "PEEP": PACKET_PEEP, "PIP": PACKET_PIP]
let PACKET_NAME_TO_METADATA = [PACKET_E_TIME: "E-Time", PACKET_I_TIME: "I-Time", PACKET_IE_RATIO: "I:E Ratio", PACKET_TVE: "TVe", PACKET_TVI: "TVi", PACKET_TVE_TVI_RATIO: "TVe/TVi", PACKET_EP_AUC: "epAUC", PACKET_IP_AUC: "ipAUC", PACKET_RR: "RR", PACKET_PEEP: "PEEP", PACKET_PIP: "PIP"]


class ServerModel {
    static var shared: ServerModel = ServerModel()
    
    private let ip = "http://54.153.100.62"
    
    private init() {
        
    }
    
    func enrollPatient(withName name: String, rpi: String, height: Int, sex: String, age: Int, completion: @escaping CompletionAPI) {
        let sex = sex == "Male" ? "M" : "F"
        let params = [name, rpi, "\(height)", sex, "\(age)"]
        
        serverAPI(at: "associate", type: "POST", withParams: params, completion: completion)
    }
    
    func getBreaths(forPatient name: String, startTime: Date, endTime: Date, completion: @escaping CompletionAPI) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = SERVER_DATE_FORMAT
        dateFormatter.timeZone = SERVER_TIMEZONE
        let params = [name, "\(dateFormatter.string(from: startTime))", "\(dateFormatter.string(from: endTime))"]
        print(params)
        serverAPI(at: "last_breaths", type: "GET", withParams: params, completion: completion)
    }
    
    func getBreathStats(forPatient name: String, startTime: Date, endTime: Date, completion: @escaping CompletionAPI) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = SERVER_DATE_FORMAT
        dateFormatter.timeZone = SERVER_TIMEZONE
        let params = [name, "\(dateFormatter.string(from: startTime))", "\(dateFormatter.string(from: endTime))"]
        serverAPI(at: "patient_stats", type: "GET", withParams: params, completion: completion)
    }
    
    func setAlertSettings(forPatient name: String, alertDTA: Bool, thresholdDTA: Int, alertBSA: Bool, thresholdBSA: Int, completion: @escaping CompletionAPI) {
        let params = [name, "\(alertDTA)", "\(thresholdDTA)", "\(alertBSA)", "\(thresholdBSA)"]
        print(params)
        
        serverAPI(at: "alert_settings", type: "POST", withParams: params, completion: completion)
    }
    
    func registerDevice(forPatient name: String, withToken token: String, completion: @escaping CompletionAPI) {
        let params = [name, token]
        
        serverAPI(at: "apn", type: "POST", withParams: params, completion: completion)
    }
    
    func disassociatePatient(named name: String, completion: @escaping CompletionAPI) {
        let params = [name]
        
        serverAPI(at: "disassociate", type: "POST", withParams: params, completion: completion)
    }
    
    func changeRPi(forPatient name: String, to rpi: String, completion: @escaping CompletionAPI) {
        let params = [name, rpi]
        
        serverAPI(at: "change_rpi", type: "POST", withParams: params, completion: completion)
    }
    
    func feedback(with data: [String: Any], completion: @escaping CompletionAPI) {
        serverAPI(at: "feedback", type: "POST", withParams: [], withData: data, completion: completion)
    }
    
    func setAlertSettings(for patient: PatientModel, to setting: AlertModel, completion: @escaping CompletionAPI) {
        var json: [String: Any] = setting.json
        json["apn"] = Storage.deviceToken
        json["patient"] = patient.name
        json["notification"] = nil
        print(json)
        
        serverAPI(at: "apn_settings", type: "POST", withParams: [], withData: json, completion: completion)
    }
    
    func removeAlertSettings(for patient: PatientModel, completion: @escaping CompletionAPI) {
        let json: [String: Any] = ["apn": Storage.deviceToken, "patient": patient.name]
        
        serverAPI(at: "apn_settings", type: "DELETE", withParams: [], withData: json, completion: completion)
    }
    
    private func serverAPI(at endPoint: String, type: String, withParams params: [String], withData data: [String: Any] = [:], completion: @escaping CompletionAPI) {
        var baseURL = "\(ip)/\(endPoint)"
        
        for param in params.compactMap({ $0.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) }) {
            baseURL += "/\(param)"
        }
        print(baseURL)
        guard let url = URL(string: baseURL) else {
            print("Something wrong with URL?")
            return
        }
        
        let session = URLSession(configuration: .default)
        var request = URLRequest(url: url)
        request.httpMethod = type
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if data.isEmpty {
            session.dataTask(with: request) { (data, response, error) in
                self.handleServerRessponse(data: data, response: response, error: error, completion: completion)
            }.resume()
        }
        else {
            guard let body = try? JSONSerialization.data(withJSONObject: data) else {
                return
            }
            session.uploadTask(with: request, from: body) { (data, response, error) in
                self.handleServerRessponse(data: data, response: response, error: error, completion: completion)
            }.resume()
        }
    }
    
    func handleServerRessponse(data: Data?, response: URLResponse?, error: Error?, completion: @escaping CompletionAPI) {
        if let response = response as? HTTPURLResponse {
            print(response)
            DispatchQueue.global(qos: .userInitiated).async {
                if response.statusCode != 200 {
                    completion(nil, NSError(domain: "HttpServerOperationErrorDomain", code: response.statusCode, userInfo: [NSLocalizedDescriptionKey: NSLocalizedString("Operation was not successful.", comment: "")]))
                }
                else {
                    completion(data, nil)
                }
            }
        }
        else {
            print("ERROR: BOTH DATA AND ERROR ARE NIL")
            completion(nil, error)
        }
    }
}
