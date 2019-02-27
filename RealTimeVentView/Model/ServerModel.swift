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
    
    private func serverAPI(at endPoint: String, type: String, withParams params: [String], completion: @escaping CompletionAPI) {
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
        session.dataTask(with: request) { (data, response, error) in
            DispatchQueue.global(qos: .userInitiated).async {
                completion(data, error)
            }
        }.resume()
    }
}
