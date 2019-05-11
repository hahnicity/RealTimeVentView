//
//  AppDelegate.swift
//  RealTimeVentView
//
//  Created by Gregory Rehm on 1/29/19.
//  Copyright © 2019 CCIL. All rights reserved.
//

import UIKit
import UserNotifications
import SimulatorRemoteNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        registerForPushNotifications()
        #if DEBUG
            //application.listenForRemoteNotifications()
        #endif
        
        if let notification = launchOptions?[UIApplication.LaunchOptionsKey.remoteNotification] as? [String: Any], let type = notification["type"] as? String {
            if type == "feedback_push" {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = SERVER_DATE_FORMAT
                dateFormatter.timeZone = SERVER_TIMEZONE
                if let name = notification["patient"] as? String, let start = notification["start_time"] as? String, let startTime = dateFormatter.date(from: start), let end = notification["end_time"] as? String, let endTime = dateFormatter.date(from: end) {
                    let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "feedbackViewController") as! FeedbackViewController
                    viewController.patient = PatientModel.searchPatient(named: name)
                    viewController.startTime = startTime
                    viewController.endTime = endTime
                    (self.window?.rootViewController as? UINavigationController)?.pushViewController(viewController, animated: true)
                }
            }
            else if type == "threshold_push" {
                if let name = notification["patient"] as? String {
                    let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "chartViewController") as! ChartViewController
                    viewController.patient = PatientModel.searchPatient(named: name)
                    (self.window?.rootViewController as? UINavigationController)?.pushViewController(viewController, animated: true)
                }
            }
        }
        
        // Override point for customization after application launch.
        return true
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("notification received")
        if let type = userInfo["type"] as? String {
            if type == "feedback_push" {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = SERVER_DATE_FORMAT
                dateFormatter.timeZone = SERVER_TIMEZONE
                print(userInfo)
                if let name = userInfo["patient"] as? String, let start = userInfo["start_time"] as? String, let startTime = dateFormatter.date(from: start), let end = userInfo["end_time"] as? String, let endTime = dateFormatter.date(from: end) {
                    let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "feedbackViewController") as! FeedbackViewController
                    viewController.patient = PatientModel.searchPatient(named: name)
                    viewController.startTime = startTime
                    viewController.endTime = endTime
                    print("\(startTime) \(endTime)")
                    (self.window?.rootViewController as? UINavigationController)?.pushViewController(viewController, animated: true)
                }
            }
            else if type == "threshold_push" {
                if let name = userInfo["patient"] as? String {
                    let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "chartViewController") as! ChartViewController
                    viewController.patient = PatientModel.searchPatient(named: name)
                    viewController.accessType = .enroll
                    (self.window?.rootViewController as? UINavigationController)?.pushViewController(viewController, animated: true)
                }
            }
        }
        else {
            completionHandler(.failed)
        }
    }
    
    func registerForPushNotifications() {
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { (granted, error) in
            guard granted else {
                print("User notification permision not granted")
                return
            }
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenParts = deviceToken.map { (data) -> String in
            return String(format: "%02.2hhx", data)
        }
        let token = tokenParts.joined()
        print("Device Token: \(token)")
        Storage.deviceToken = token
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Device token registration failed: \(error)")
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .sound, .badge])
    }
    

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

