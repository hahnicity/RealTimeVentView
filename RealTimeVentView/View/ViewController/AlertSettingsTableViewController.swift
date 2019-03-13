//
//  AlertSettingsTableViewController.swift
//  RealTimeVentView
//
//  Created by user149673 on 2/11/19.
//  Copyright © 2019 CCIL. All rights reserved.
//

import UIKit

enum AlertSettingType {
    case label, alertSwitch, textField, button
}

enum AlertAccessType {
    case main, enroll
}

class AlertSettingsTableViewController: UITableViewController, ButtonTableViewCellDelegate, TextFieldTableViewCellDelegate, SwitchTableViewCellDelegate {
    

    var cellTypes: [AlertSettingType] = [.alertSwitch, .alertSwitch, .label, .textField, .alertSwitch, .label, .textField, .alertSwitch, .label, .textField, .button]
    var cellTitles = ["Notification", "Alert for DTA", "DTA Threshold Past 10 Mins", "", "Alert for BSA", "BSA Threshold Past 10 Mins", "", "Alert for TVV", "TVV Threshold Past 10 Mins", "", ""]
    var index = 0
    var patient = PatientModel()
    var alertSetting = AlertModel()
    var accessType: AlertAccessType = .main
    
    var alertNotification = false
    var alertDTA = false
    var thresholdDTA = ""
    var alertBSA = false
    var thresholdBSA = ""
    var alertTVV = false
    var thresholdTVV = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        alertSetting = AlertModel(at: index)
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        alertNotification = alertSetting.notification
        alertDTA = alertSetting.alertDTA
        thresholdDTA = "\(alertSetting.thresholdDTA)"
        alertBSA = alertSetting.alertBSA
        thresholdBSA = "\(alertSetting.thresholdBSA)"
        alertTVV = alertSetting.alertTVV
        thresholdTVV = "\(alertSetting.thresholdTVV)"
        tableView.reloadData()
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return cellTypes.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if cellTypes[indexPath.row] == .label {
            let cell = (tableView.dequeueReusableCell(withIdentifier: "labelCell") ?? UITableViewCell(style: .subtitle, reuseIdentifier: "labelCell"))
            cell.textLabel?.text = cellTitles[indexPath.row]
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
        else if cellTypes[indexPath.row] == .button {
            let cell = (tableView.dequeueReusableCell(withIdentifier: "buttonCell") ?? UITableViewCell(style: .default, reuseIdentifier: "buttonCell")) as! ButtonTableViewCell
            cell.delegate = self
            return cell
        }
        else if cellTypes[indexPath.row] == .alertSwitch {
            let cell = (tableView.dequeueReusableCell(withIdentifier: "switchCell") ?? UITableViewCell(style: .default, reuseIdentifier: "switchCell")) as! SwitchTableViewCell
            cell.textLabel?.text = cellTitles[indexPath.row]
            cell.delegate = self
            switch(indexPath.row) {
            case 0:
                cell.alertSwitch.isOn = alertSetting.notification
                cell.type = .notification
            case 1:
                cell.alertSwitch.isOn = alertSetting.alertDTA
                cell.isUserInteractionEnabled = alertNotification
                cell.textLabel?.isEnabled = alertNotification
                cell.alertSwitch.isEnabled = alertNotification
                cell.type = .dta
            case 4:
                cell.alertSwitch.isOn = alertSetting.alertBSA
                cell.isUserInteractionEnabled = alertNotification
                cell.textLabel?.isEnabled = alertNotification
                cell.alertSwitch.isEnabled = alertNotification
                cell.type = .bsa
            case 7:
                cell.alertSwitch.isOn = alertSetting.alertTVV
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
                cell.textField.text = "\(alertSetting.thresholdDTA)"
                cell.isUserInteractionEnabled = alertDTA && alertNotification
                cell.textLabel?.isEnabled = alertDTA && alertNotification
                cell.textField.isEnabled = alertDTA && alertNotification
                cell.type = .thresholdDTA
            case 6:
                cell.textField.text = "\(alertSetting.thresholdBSA)"
                cell.isUserInteractionEnabled = alertBSA && alertNotification
                cell.textLabel?.isEnabled = alertBSA && alertNotification
                cell.textField.isEnabled = alertBSA && alertNotification
                cell.type = .thresholdBSA
            case 9:
                cell.textField.text = "\(alertSetting.thresholdTVV)"
                cell.isUserInteractionEnabled = alertTVV && alertNotification
                cell.textLabel?.isEnabled = alertTVV && alertNotification
                cell.textField.isEnabled = alertTVV && alertNotification
                cell.type = .thresholdTVV
            default: ()
            }
            return cell
        }
        

        // Configure the cell...
    }
    
    func enableCells(_ value: Bool) {
        for index in 1 ..< cellTypes.count - 1 {
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
            let cell = tableView.cellForRow(at: IndexPath(row: index, section: 0))
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
            if let cell = tableView.cellForRow(at: IndexPath(row: 2, section: 0)) {
                cell.isUserInteractionEnabled = value
                cell.textLabel?.isEnabled = value
            }
            if let cell = tableView.cellForRow(at: IndexPath(row: 3, section: 0)) as? TextFieldTableViewCell {
                cell.isUserInteractionEnabled = value
                cell.textField.isEnabled = value
            }
            alertDTA = value
            tableView.beginUpdates()
            tableView.endUpdates()
        case .bsa:
            if let cell = tableView.cellForRow(at: IndexPath(row: 5, section: 0)) {
                cell.isUserInteractionEnabled = value
                cell.textLabel?.isEnabled = value
            }
            if let cell = tableView.cellForRow(at: IndexPath(row: 6, section: 0)) as? TextFieldTableViewCell {
                cell.isUserInteractionEnabled = value
                cell.textField.isEnabled = value
            }
            alertBSA = value
            tableView.beginUpdates()
            tableView.endUpdates()
        case .tvv:
            if let cell = tableView.cellForRow(at: IndexPath(row: 8, section: 0)) {
                cell.textLabel?.isEnabled = value
            }
            if let cell = tableView.cellForRow(at: IndexPath(row: 9, section: 0)) as? TextFieldTableViewCell {
                cell.isUserInteractionEnabled = value
                cell.textField.isEnabled = value
            }
            alertTVV = value
            tableView.beginUpdates()
            tableView.endUpdates()
        default: ()
        }
    }
    
    func editingText(_ text: String) {
        
    }
    
    func textChanged(ofType type: TextFieldType, to value: String) {
        print(value)
        switch type {
        case .thresholdDTA:
            thresholdDTA = value
        case .thresholdBSA:
            thresholdBSA = value
        case .thresholdTVV:
            thresholdTVV = value
        default: ()
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func submitForm() {
        if hasFormError(withDTA: thresholdDTA, BSA: thresholdBSA, TVV: thresholdTVV) {
            return
        }
        
        let lock = NSLock()
        alertSetting = AlertModel(withAlertDTA: alertDTA, thresholdDTA: Int(thresholdDTA)!, alertBSA: alertBSA, thresholdBSA: Int(thresholdBSA)!, alertTVV: alertTVV, thresholdTVV: Int(thresholdTVV)!, notification: alertNotification)

        alertSetting.update(for: patient, at: index) { (data, error) in
            if let error = error {
                self.showAlert(withTitle: "Alert Update Error", message: error.localizedDescription)
                lock.unlock()
                return
            }
            if self.accessType == .main {
                DispatchQueue.main.async {
                    self.navigationController?.popToRootViewController(animated: true)
                }
            }
            if self.accessType == .enroll {
                let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "chartViewController") as! ChartViewController
                viewController.patient = self.patient
                viewController.accessType = .enroll
                DispatchQueue.main.async {
                    self.navigationController?.pushViewController(viewController, animated: true)
                }
            }
        }
    }
    
    func hasFormError(withDTA dta: String, BSA bsa: String, TVV tvv: String) -> Bool {
        if dta.count == 0 {
            showAlert(withTitle: "Alert Settings Error", message: "Please enter the DTA threshold for the patient.")
            return true
        }
        if bsa.count == 0 {
            showAlert(withTitle: "Alert Settings Error", message: "Please enter the BSA threshold for the patient.")
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
    
    func showAlert(withTitle title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "Confirm", style: .cancel) { (alertAction) in
            
        }
        alert.addAction(action)
        DispatchQueue.main.async {
            self.present(alert, animated: true)
        }
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
