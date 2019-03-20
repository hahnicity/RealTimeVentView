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

class ConfigurationTableViewController: UITableViewController, ButtonTableViewCellDelegate, SwitchTableViewCellDelegate, TextFieldTableViewCellDelegate {
    

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
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        alertNotification = defaultAlert.notification
        alertDTA = defaultAlert.alertDTA
        thresholdDTA = "\(defaultAlert.thresholdDTA)"
        alertBSA = defaultAlert.alertBSA
        thresholdBSA = "\(defaultAlert.thresholdBSA)"
        alertTVV = defaultAlert.alertTVV
        thresholdTVV = "\(defaultAlert.thresholdTVV)"
        tableView.reloadData()
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        self.view.endEditing(true)
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return sectionHeaders.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        switch(section) {
        case 0:
            return configCellTypes.count
        case 1:
            return alertCellTypes.count
        default: ()
        }
        return 0
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionHeaders[section]
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        switch(indexPath.section) {
        case 0:
            return getConfigCell(for: tableView, at: indexPath)
        case 1:
            return getAlertCell(for: tableView, at:indexPath)
        default: ()
        }

        // Configure the cell...

        return UITableViewCell()
    }
    
    func getConfigCell(for tableView: UITableView, at indexPath: IndexPath) -> UITableViewCell {
        if configCellTypes[indexPath.row] == .label {
            let cell = (tableView.dequeueReusableCell(withIdentifier: "labelCell") ?? UITableViewCell(style: .subtitle, reuseIdentifier: "labelCell"))
            cell.textLabel?.text = configCellTitles[indexPath.row]
            cell.detailTextLabel?.text = ""
            return cell
        }
        else if configCellTypes[indexPath.row] == .alertSwitch {
            let cell = (tableView.dequeueReusableCell(withIdentifier: "switchCell") ?? UITableViewCell(style: .subtitle, reuseIdentifier: "switchCell")) as! SwitchTableViewCell
            cell.textLabel?.text = configCellTitles[indexPath.row]
            cell.alertSwitch.isOn = UIApplication.shared.isRegisteredForRemoteNotifications
            cell.type = .notificationAll
            cell.delegate = self
            return cell
        }
        else {
            let cell = (tableView.dequeueReusableCell(withIdentifier: "textFieldCell") ?? UITableViewCell(style: .default, reuseIdentifier: "textFieldCell")) as! TextFieldTableViewCell
            switch(indexPath.row) {
            case 1:
                cell.textField.text = "\(Storage.loadTimeFrame)"
                cell.type = .loadTimeFrame
            case 3:
                cell.textField.text = "\(Storage.updateInterval)"
                cell.type = .updateInterval
            case 5:
                cell.textField.text = "\(Storage.numFeedbackBreaths)"
                cell.type = .numFeedbackBreaths
            default: ()
            }
            return cell
        }
        
    }
    
    func getAlertCell(for tableView: UITableView, at indexPath: IndexPath) -> UITableViewCell {
        if alertCellTypes[indexPath.row] == .label {
            let cell = (tableView.dequeueReusableCell(withIdentifier: "labelCell") ?? UITableViewCell(style: .subtitle, reuseIdentifier: "labelCell"))
            cell.textLabel?.text = alertCellTitles[indexPath.row]
            cell.detailTextLabel?.text = ""
            
            switch indexPath.row {
            case 2:
                cell.isUserInteractionEnabled = alertNotification && alertDTA
                cell.textLabel?.isEnabled = alertNotification && alertDTA
            case 5:
                cell.isUserInteractionEnabled = alertNotification && alertBSA
                cell.textLabel?.isEnabled = alertNotification && alertBSA
            case 8:
                cell.isUserInteractionEnabled = alertNotification && alertTVV
                cell.textLabel?.isEnabled = alertNotification && alertTVV
            default: ()
            }
 
            return cell
        }
        else if alertCellTypes[indexPath.row] == .button {
            let cell = (tableView.dequeueReusableCell(withIdentifier: "buttonCell") ?? UITableViewCell(style: .default, reuseIdentifier: "buttonCell")) as! ButtonTableViewCell
            cell.delegate = self
            return cell
        }
        else if alertCellTypes[indexPath.row] == .alertSwitch {
            let cell = (tableView.dequeueReusableCell(withIdentifier: "switchCell") ?? UITableViewCell(style: .default, reuseIdentifier: "switchCell")) as! SwitchTableViewCell
            cell.textLabel?.text = alertCellTitles[indexPath.row]
            cell.delegate = self
            switch(indexPath.row) {
            case 0:
                cell.alertSwitch.isOn = defaultAlert.notification
                cell.type = .notification
            case 1:
                cell.alertSwitch.isOn = defaultAlert.alertDTA
                cell.isUserInteractionEnabled = alertNotification
                cell.textLabel?.isEnabled = alertNotification
                cell.alertSwitch.isEnabled = alertNotification
                cell.type = .dta
            case 4:
                cell.alertSwitch.isOn = defaultAlert.alertBSA
                cell.isUserInteractionEnabled = alertNotification
                cell.textLabel?.isEnabled = alertNotification
                cell.alertSwitch.isEnabled = alertNotification
                cell.type = .bsa
            case 7:
                cell.alertSwitch.isOn = defaultAlert.alertTVV
                cell.isUserInteractionEnabled = alertNotification
                cell.textLabel?.isEnabled = alertNotification
                cell.alertSwitch.isEnabled = alertNotification
                cell.type = .tvv
            default: ()
            }
            return cell
        }
        else {
            let cell = (tableView.dequeueReusableCell(withIdentifier: "textFieldCell") ?? UITableViewCell(style: .default, reuseIdentifier: "textFieldCell")) as! TextFieldTableViewCell
            cell.delegate = self
            switch(indexPath.row) {
            case 3:
                cell.textField.text = "\(defaultAlert.thresholdDTA)"
                cell.isUserInteractionEnabled = alertDTA && alertNotification
                cell.textLabel?.isEnabled = alertDTA && alertNotification
                cell.textField.isEnabled = alertDTA && alertNotification
                cell.type = .thresholdDTA
            case 6:
                cell.textField.text = "\(defaultAlert.thresholdBSA)"
                cell.isUserInteractionEnabled = alertBSA && alertNotification
                cell.textLabel?.isEnabled = alertBSA && alertNotification
                cell.textField.isEnabled = alertBSA && alertNotification
                cell.type = .thresholdBSA
            case 9:
                cell.textField.text = "\(defaultAlert.thresholdTVV)"
                cell.isUserInteractionEnabled = alertTVV && alertNotification
                cell.textLabel?.isEnabled = alertTVV && alertNotification
                cell.textField.isEnabled = alertTVV && alertNotification
                cell.type = .thresholdTVV
            default: ()
            }
            return cell
        }
    }
    
    func enableCells(_ value: Bool) {
        for index in 1 ..< alertCellTypes.count - 1 {
            var new = value
            if index < 4 {
                new = alertDTA && value
            }
            else if index < 7 {
                new = alertBSA && value
            }
            else if index < 10 {
                new = alertTVV && value
            }
            let cell = tableView.cellForRow(at: IndexPath(row: index, section: 1))
            cell?.isUserInteractionEnabled = value
            if let cell = cell as? SwitchTableViewCell {
                cell.textLabel?.isEnabled = value
                cell.alertSwitch.isEnabled = value
            }
            else if let cell = cell as? TextFieldTableViewCell {
                cell.textLabel?.isEnabled = new
                cell.textField.isEnabled = new
            }
            else if let cell = cell {
                cell.textLabel?.isEnabled = new
            }
        }
    }

    
    func switchChanged(ofType type: SwitchType, to value: Bool) {
        switch type {
        case .notification:
            enableCells(value)
            alertNotification = value
            tableView.beginUpdates()
            tableView.endUpdates()
        case .dta:
            if let cell = tableView.cellForRow(at: IndexPath(row: 2, section: 1)) {
                cell.isUserInteractionEnabled = value
                cell.textLabel?.isEnabled = value
            }
            if let cell = tableView.cellForRow(at: IndexPath(row: 3, section: 1)) as? TextFieldTableViewCell {
                cell.isUserInteractionEnabled = value
                cell.textField.isEnabled = value
            }
            alertDTA = value
            tableView.beginUpdates()
            tableView.endUpdates()
        case .bsa:
            if let cell = tableView.cellForRow(at: IndexPath(row: 5, section: 1)) {
                cell.isUserInteractionEnabled = value
                cell.textLabel?.isEnabled = value
            }
            if let cell = tableView.cellForRow(at: IndexPath(row: 6, section: 1)) as? TextFieldTableViewCell {
                cell.isUserInteractionEnabled = value
                cell.textField.isEnabled = value
            }
            alertBSA = value
            tableView.beginUpdates()
            tableView.endUpdates()
        case .tvv:
            if let cell = tableView.cellForRow(at: IndexPath(row: 8, section: 1)) {
                cell.textLabel?.isEnabled = value
            }
            if let cell = tableView.cellForRow(at: IndexPath(row: 9, section: 1)) as? TextFieldTableViewCell {
                cell.isUserInteractionEnabled = value
                cell.textField.isEnabled = value
            }
            alertTVV = value
            tableView.beginUpdates()
            tableView.endUpdates()
        case .notificationAll:
            notification = value
        }
    }
    
    func editingText(_ text: String) {
        
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
    
    func submitForm() {
        self.view.endEditing(true)
        
        if hasAppConfigError(withLoadTimeFrame: loadTimeFrame, updateInterval: updateInterval, numBreathFeedback: numFeedbackBreaths) || hasDefaultSettingsError(withDTA: thresholdDTA, BSA: thresholdBSA, TVV: thresholdTVV) {
            return
        }
        
        let lock = NSLock()
        lock.lock()
        print("\(UIApplication.shared.isRegisteredForRemoteNotifications) and \(notification)")
        if !UIApplication.shared.isRegisteredForRemoteNotifications && notification {
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
        
        if UIApplication.shared.isRegisteredForRemoteNotifications && !notification {
            DispatchQueue.main.async {
                UIApplication.shared.unregisterForRemoteNotifications()
            }
        }
        Storage.loadTimeFrame = Int(loadTimeFrame)!
        Storage.updateInterval = Int(updateInterval)!
        Storage.numFeedbackBreaths = Int(numFeedbackBreaths)!
        Storage.defaultAlert = AlertModel(withAlertDTA: alertDTA, thresholdDTA: Int(thresholdDTA)!, alertBSA: alertBSA, thresholdBSA: Int(thresholdBSA)!, alertTVV: alertTVV, thresholdTVV: Int(thresholdTVV)!, notification: alertNotification).json
        
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    func hasDefaultSettingsError(withDTA dta: String, BSA bsa: String, TVV tvv: String) -> Bool {
        if dta.count == 0 {
            showAlert(withTitle: "Default Alert Settings Error", message: "Please enter the DTA threshold for the patient.")
            return true
        }
        if bsa.count == 0 {
            showAlert(withTitle: "Default Alert Settings Error", message: "Please enter the BSA threshold for the patient.")
            return true
        }
        if tvv.count == 0 {
            showAlert(withTitle: "Alert Settings Error", message: "Please enter the TVV threshold for the patient.")
            return true
        }
        
        guard let temp_dta = Int(dta), temp_dta > 0 else {
            showAlert(withTitle: "Alert Settings Error", message: "The DTA threshold for the patient must be a nonzero number.")
            return true
        }
        
        guard let temp_bsa = Int(bsa), temp_bsa > 0 else {
            showAlert(withTitle: "Alert Settings Error", message: "The BSA threshold for the patient must be a nonzero number.")
            return true
        }
        
        guard let temp_tvv = Int(tvv), temp_tvv > 0 else {
            showAlert(withTitle: "Alert Settings Error", message: "The TVV threshold for the patient must be a nonzero number.")
            return true
        }
        
        return false
    }
    
    func hasAppConfigError(withLoadTimeFrame loadTimeFrame: String, updateInterval: String, numBreathFeedback: String) -> Bool {
        
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
