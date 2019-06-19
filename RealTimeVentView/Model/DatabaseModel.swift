//
//  DatabaseModel.swift
//  RealTimeVentView
//
//  Created by user149673 on 5/24/19.
//  Copyright © 2019 CCIL. All rights reserved.
//

import Foundation
import SQLite

let TABLE_VISIBLE_STATS = "vstats"
let TABLE_ALERT_LOGS = "alertlogs"
let COL_PATIENT_NAME = "patient"
let COL_STAT_NAME = "stat"
let COL_INDEX = "index"
let COL_LOG_DATE = "date"
let COL_LOG_TYPE = "type"

let DEFAULT_VISIBLE_STATS = ["TVi", "TVe", "RR", "PEEP"]

class DatabaseModel {
    static let shared = DatabaseModel()
    private var db: Connection
    
    private init() {
        let path = NSSearchPathForDirectoriesInDomains(
            .documentDirectory, .userDomainMask, true
            ).first!
        print(path)
        self.db = try! Connection("\(path)/db.sqlite3")
        do {
            let visibleStats = Table(TABLE_VISIBLE_STATS)
            let alertLogs = Table(TABLE_ALERT_LOGS)
            let patientName = Expression<String>(COL_PATIENT_NAME)
            let index = Expression<Int64>(COL_INDEX)
            let statName = Expression<String>(COL_STAT_NAME)
            let logDate = Expression<Date>(COL_LOG_DATE)
            let logType = Expression<String>(COL_LOG_TYPE)
            
            try db.run(visibleStats.create(ifNotExists: true, block: { (t) in
                t.column(patientName)
                t.column(index)
                t.column(statName)
            }))
            
            try db.run(alertLogs.create(ifNotExists: true, block: { (t) in
                t.column(patientName)
                t.column(logDate)
                t.column(logType)
            }))
        } catch {
            print("Error: \(error)")
        }
        
    }
    
    func initVisibleStats(for patient: String) {
        do {
            let visibleStats = Table(TABLE_VISIBLE_STATS)
            let patientName = Expression<String>(COL_PATIENT_NAME)
            let index = Expression<Int64>(COL_INDEX)
            let statName = Expression<String>(COL_STAT_NAME)
            
            for (i, stat) in DEFAULT_VISIBLE_STATS.enumerated() {
                try db.run(visibleStats.insert(patientName <- patient, index <- Int64(i), statName <- stat))
            }
        } catch {
            print("Error: \(error)")
        }
    }
    
    func getVisibleStats(for patient: String) -> [String] {
        do {
            let visibleStats = Table(TABLE_VISIBLE_STATS)
            let patientName = Expression<String>(COL_PATIENT_NAME)
            let index = Expression<Int64>(COL_INDEX)
            let statName = Expression<String>(COL_STAT_NAME)
            
            let list = visibleStats.filter(patientName == patient).order(index.asc)
            
            var stats: [String] = []
            
            for stat in try db.prepare(list) {
                stats.append(stat[statName])
            }
            
            return stats
        } catch {
            print("Error: \(error)")
        }
        
        return []
    }
    
    func storeVisibleStats(_ stats: [String], for patient: String) {
        do {
            let visibleStats = Table(TABLE_VISIBLE_STATS)
            let patientName = Expression<String>(COL_PATIENT_NAME)
            let index = Expression<Int64>(COL_INDEX)
            let statName = Expression<String>(COL_STAT_NAME)
            
            for (i, stat) in stats.enumerated() {
                try db.run(visibleStats.insert(patientName <- patient, index <- Int64(i), statName <- stat))
            }
        } catch {
            print("Error: \(error)")
        }
    }
    
    func logAlert(_ alerts: [[String: Any]], for patient: String, at date: Date) {
        do {
            let alertlogs = Table(TABLE_ALERT_LOGS)
            let patientName = Expression<String>(COL_PATIENT_NAME)
            let logDate = Expression<Date>(COL_LOG_DATE)
            let logType = Expression<String>(COL_LOG_TYPE)
            
            var alertString = ""
            alerts.forEach { (alert) in
                guard let type = alert["alert"] as? String, let count = alert["count"] else {
                    return
                }
                alertString += "\(type):\(count) "
            }
            
            try db.run(alertlogs.insert(patientName <- patient, logDate <- date, logType <- alertString))
        } catch {
            print("Error: \(error)")
        }
    }
    
    func getAlerts(for patient: String) -> [([(String, Int)], Date)] {
        do {
            let alertlogs = Table(TABLE_ALERT_LOGS)
            let patientName = Expression<String>(COL_PATIENT_NAME)
            let logDate = Expression<Date>(COL_LOG_DATE)
            let logType = Expression<String>(COL_LOG_TYPE)
            
            let old = alertlogs.filter(logDate < Date(timeIntervalSinceNow: -86400.0))
            let list = alertlogs.filter(patientName == patient && logDate > Date(timeIntervalSinceNow: -86400.0)).order(logDate.desc)
            
            var alerts: [([(String, Int)], Date)] = []
            
            try db.prepare(list).forEach({ (alert) in
                let l = alert[logType].split(separator: " ")
                var al: [(String, Int)] = []
                l.forEach({ (t) in
                    guard let t = t.split(separator: ":").first,
                        let temp = t.split(separator: ":").last,
                        let count = Int(String(temp)) else {
                        return
                    }
                    al.append((String(t), count))
                })
                alerts.append((al, alert[logDate]))
            })
            

            try db.run(old.delete())
            
            return alerts
        } catch {
            print("Error: \(error)")
        }
        return []
    }
    
    func clearRecord(for patient: String) {
        clearRecord(for: patient, in: TABLE_VISIBLE_STATS)
        clearRecord(for: patient, in: TABLE_ALERT_LOGS)
    }
    
    func clearRecord(for patient: String, in tableName: String) {
        do {
            let table = Table(tableName)
            let patientName = Expression<String>(COL_PATIENT_NAME)
            let rows = table.filter(patientName == patient)
            
            try db.run(rows.delete())
        } catch {
            print("Error: \(error)")
        }
    }
}
