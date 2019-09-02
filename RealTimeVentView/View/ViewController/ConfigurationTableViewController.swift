//
//  ConfigurationTableViewController.swift
//  RealTimeVentView
//
//  Created by user149673 on 2/11/19.
//  Copyright © 2019 CCIL. All rights reserved.
//

import UIKit
import UserNotifications

enum ConfigType {
    case label, textField, alertSwitch
}

class ConfigurationTableViewController: UITableViewController {
    

    var alertCellTypes: [AlertSettingType] = [.alertSwitch, .alertSwitch, .label, .textField, .alertSwitch, .label, .textField, .alertSwitch, .label, .textField, .button]
    var alertCellTitles = ["Notification", "Alert for DTA", "DTA Threshold Past 10 Mins", "", "Alert for BSA", "BSA Threshold Past 10 Mins", "", "Alert for TVV", "TVV Threshold Past 10 Mins", "", ""]
    
    var configCellTypes: [ConfigType] = [.label, .textField, .label, .textField, .label, .textField, .alertSwitch]
    var configCellTitles = ["Load Time Frame (minutes)", "", "Update Interval (seconds)", "", "Number of Breaths for Feedback", "", "Notifications"]
    
    var sectionHeaders = ["App Configuration", "Default Alert Settings"]
    
    var defaultAlert = AlertModel()
    
    var loadTimeFrame = "\(Storage.loadTimeFrame)"
    var updateInterval = "\(Storage.updateInterval)"
    var numFeedbackBreaths = "\(Storage.numFeedbackBreaths)"
    var notification = UIApplication.shared.isRegisteredForRemoteNotifications
    var alertNotification = false
    var alertDTA = false
    var thresholdDTA = ""
    var alertBSA = false
    var thresholdBSA = ""
    var alertTVV = false
    var thresholdTVV = ""
    
    @IBOutlet weak var loadTimeFrameTextField: UITextField!
    @IBOutlet weak var updateIntervalTextField: UITextField!
    @IBOutlet weak var numFeedbackBreathsTextField: UITextField!
    @IBOutlet weak var notificationSwitch: UISwitch!
    @IBOutlet weak var defaultNotificationSwitch: UISwitch!
    @IBOutlet weak var minutesBetweenAlertsText: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadTimeFrameTextField.text = "\(Storage.loadTimeFrame)"
        updateIntervalTextField.text = "\(Storage.updateInterval)"
        numFeedbackBreathsTextField.text = "\(Storage.numFeedbackBreaths)"
        notificationSwitch.isOn = UIApplication.shared.isRegisteredForRemoteNotifications
        let defaultAlert = AlertModel()
        defaultNotificationSwitch.isOn = defaultAlert.notification
        minutesBetweenAlertsText.text = "\(defaultAlert.alertMV.timeFrame)"
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    // MARK: - Table view data source
    
    

    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 1, indexPath.row > 0 {
            let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "asyncAlertSettingsTableViewController") as! AsyncAlertSettingsTableViewController
            viewController.alert = defaultAlert
            viewController.type = AsyncType(rawValue: indexPath.row - 1) ?? .bsa
            self.navigationController?.pushViewController(viewController, animated: true)
        }
        self.view.endEditing(true)
    }

    
    func textChanged(ofType type: TextFieldType, to value: String) {
        print(value)
        switch type {
        case .loadTimeFrame:
            loadTimeFrame = value
        case .updateInterval:
            updateInterval = value
        case .numFeedbackBreaths:
            numFeedbackBreaths = value
        case .thresholdDTA:
            thresholdDTA = value
        case .thresholdBSA:
            thresholdBSA = value
        case .thresholdTVV:
            thresholdTVV = value
        }
    }
    
    @IBAction func submit(_ sender: UIBarButtonItem) {
        self.view.endEditing(true)
        
        guard let loadTimeFrame = loadTimeFrameTextField.text,
            let updateInterval = updateIntervalTextField.text,
            let numFeedbackBreaths = numFeedbackBreathsTextField.text,
            let minutes = minutesBetweenAlertsText.text
            else {
                print("Number not retrieved")
                return
        }
        
        if hasAppConfigError(withLoadTimeFrame: loadTimeFrame, updateInterval: updateInterval, numBreathFeedback: numFeedbackBreaths, withMinutesBetweenAlerts: minutes) {
            return
        }
        
        let lock = NSLock()
        lock.lock()
        print("\(UIApplication.shared.isRegisteredForRemoteNotifications) and \(notificationSwitch.isOn)")
        if !UIApplication.shared.isRegisteredForRemoteNotifications && notificationSwitch.isOn {
            print("HERE")
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { (granted, error) in
                guard granted else {
                    print("User notification permision not granted")
                    lock.unlock()
                    return
                }
                lock.unlock()
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
                
            }
        }
        else {
            lock.unlock()
        }
        lock.lock()
        
        if UIApplication.shared.isRegisteredForRemoteNotifications && !notificationSwitch.isOn {
            DispatchQueue.main.async {
                UIApplication.shared.unregisterForRemoteNotifications()
            }
        }
        defaultAlert.notification = defaultNotificationSwitch.isOn
        Storage.loadTimeFrame = Int(loadTimeFrame)!
        Storage.updateInterval = Int(updateInterval)!
        Storage.numFeedbackBreaths = Int(numFeedbackBreaths)!
        Storage.defaultAlert = defaultAlert.json
        Storage.defaultAlert["minutes_between_alerts"] = Int(minutes)
        
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    func hasAppConfigError(withLoadTimeFrame loadTimeFrame: String, updateInterval: String, numBreathFeedback: String, withMinutesBetweenAlerts minutesBetweenAlerts: String) -> Bool {
        
        if minutesBetweenAlerts.count == 0 {
            showAlert(withTitle: "Alert Settings Error", message: "Please enter the minutes between alerts for the patient.")
            return true
        }
        
        guard let freq = Int(minutesBetweenAlerts), freq > 0 else {
            showAlert(withTitle: "Alert Settings Error", message: "The minutes between alerts must be a positive number.")
            return true
        }
        
        if loadTimeFrame.count == 0 {
            showAlert(withTitle: "App Configuration Error", message: "Please enter the time frame of the data load.")
            return true
        }
        
        guard let temp_ltf = Int(loadTimeFrame) else {
            showAlert(withTitle: "App Configuration Error", message: "The time frame should be a nonzero number.")
            return true
        }
        
        if temp_ltf <= 0 {
            showAlert(withTitle: "App Configuration Error", message: "The time frame should be a nonzero number.")
            return true
        }
        
        if updateInterval.count == 0 {
            showAlert(withTitle: "App Configuration Error", message: "Please enter the time interval of the view update.")
            return true
        }
        
        guard let temp_ui = Int(updateInterval) else {
            showAlert(withTitle: "App Configuration Error", message: "The update interval should be a nonzero number.")
            return true
        }
        
        if temp_ui <= 0 {
            showAlert(withTitle: "App Configuration Error", message: "The update interval should be a nonzero number.")
            return true
        }
        
        if numBreathFeedback.count == 0 {
            showAlert(withTitle: "App Configuration Error", message: "Please enter the number of breaths for feedback.")
            return true
        }
        
        guard let temp_nbf = Int(numBreathFeedback) else {
            showAlert(withTitle: "App Configuration Error", message: "The number of breath of feeback should be a nonzero number.")
            return true
        }
        
        if temp_nbf <= 0 {
            showAlert(withTitle: "App Configuration Error", message: "The number of breath of feeback should be a nonzero number.")
            return true
        }
        
        return false
    }
    
    func showAlert(withTitle title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "Confirm", style: .cancel) { (alertAction) in
            
        }
        alert.addAction(action)
        self.present(alert, animated: true)
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
