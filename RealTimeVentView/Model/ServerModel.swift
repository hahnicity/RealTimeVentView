//
//  ServerModel.swift
//  RealTimeVentView
//
//  Created by user149673 on 2/15/19.
//  Copyright © 2019 CCIL. All rights reserved.
//

import Foundation

typealias CompletionAPI = (Data?, Error?) -> ()

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
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateFormatter.timeZone = TimeZone(abbreviation: "GMT")
        let params = [name, "\(dateFormatter.string(from: startTime))", "\(dateFormatter.string(from: endTime))"]
        print(params)
        serverAPI(at: "last_breaths", type: "GET", withParams: params, completion: completion)
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
        let json: [String: Any] = ["apn": Storage.deviceToken, "patient": patient.name, "alert_for_dta": setting.alertDTA, "dta_alert_freq": setting.thresholdDTA, "alert_for_bsa": setting.alertBSA, "bsa_alert_freq": setting.thresholdBSA, "alert_for_tvv": setting.alertTVV, "tvv_alert_freq": setting.thresholdTVV]
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
        print(data)
        print(response)
        print(error)
        if let response = response as? HTTPURLResponse {
            
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
