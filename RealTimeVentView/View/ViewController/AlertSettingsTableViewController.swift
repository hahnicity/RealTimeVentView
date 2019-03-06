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

class AlertSettingsTableViewController: UITableViewController, ButtonTableViewCellDelegate {
    

    var cellTypes: [AlertSettingType] = [.alertSwitch, .label, .textField, .alertSwitch, .label, .textField, .button]
    var cellTitles = ["Alert for DTA", "DTA Threshold Past Hour", "", "Alert for BSA", "BSA Threshold Past Hour", "", ""]
    var index = 0
    var patient = PatientModel()
    var alertSetting = AlertModel()
    var accessType: AlertAccessType = .main
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        alertSetting = AlertModel(at: index)
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

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
            switch(indexPath.row) {
            case 0:
                cell.alertSwitch.isOn = alertSetting.alertDTA
            case 3:
                cell.alertSwitch.isOn = alertSetting.alertBSA
            default: ()
            }
            return cell
        }
        else {
            let cell = (tableView.dequeueReusableCell(withIdentifier: "textFieldCell") ?? UITableViewCell(style: .default, reuseIdentifier: "textFieldCell")) as! TextFieldTableViewCell
            switch(indexPath.row) {
            case 2:
                cell.textField.text = "\(alertSetting.thresholdDTA)"
            case 5:
                cell.textField.text = "\(alertSetting.thresholdBSA)"
            default: ()
            }
            return cell
        }
        

        // Configure the cell...
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func submitForm() {
        guard let dtaOn = (tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? SwitchTableViewCell)?.alertSwitch.isOn,
            let dta = (tableView.cellForRow(at: IndexPath(row: 2, section: 0)) as? TextFieldTableViewCell)?.textField.text,
            let bsaOn = (tableView.cellForRow(at: IndexPath(row: 3, section: 0)) as? SwitchTableViewCell)?.alertSwitch.isOn,
            let bsa = (tableView.cellForRow(at: IndexPath(row: 5, section: 0)) as? TextFieldTableViewCell)?.textField.text else {
                print("DTA BSA Read Error")
                return
        }
        
        if hasFormError(withDTA: dta, BSA: bsa) {
            return
        }
        
        let lock = NSLock()
        alertSetting = AlertModel(withAlertDTA: dtaOn, thresholdDTA: Int(dta)!, alertBSA: bsaOn, thresholdBSA: Int(bsa)!)
        lock.lock()
        alertSetting.update(for: patient, at: index) { (data, error) in
            if let error = error {
                self.showAlert(withTitle: "Alert Update Error", message: error.localizedDescription)
                lock.unlock()
                return
            }
            lock.unlock()
        }
        
        lock.lock()
        lock.unlock()
        
        if accessType == .main {
            self.navigationController?.popToRootViewController(animated: true)
        }
        if accessType == .enroll {
            let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "chartViewController") as! ChartViewController
            viewController.patient = patient
            viewController.accessType = .enroll
            self.navigationController?.pushViewController(viewController, animated: true)
        }
    }
    
    func hasFormError(withDTA dta: String, BSA bsa: String) -> Bool {
        if dta.count == 0 {
            showAlert(withTitle: "Alert Settings Error", message: "Please enter the DTA thrshold for the patient.")
            return true
        }
        if bsa.count == 0 {
            showAlert(withTitle: "Alert Settings Error", message: "Please enter the BSA thrshold for the patient.")
            return true
        }
        guard let temp_dta = Int(dta) else {
            showAlert(withTitle: "Alert Settings Error", message: "The DTA threshold for the patient must be a nonzero number.")
            return true
        }
        
        if temp_dta <= 0 {
            showAlert(withTitle: "Alert Settings Error", message: "The DTA threshold for the patient must be a nonzero number.")
            return true
        }
        
        guard let temp_bsa = Int(bsa) else {
            showAlert(withTitle: "Alert Settings Error", message: "The BSA threshold for the patient must be a nonzero number.")
            return true
        }
        
        if temp_bsa <= 0 {
            showAlert(withTitle: "Alert Settings Error", message: "The BSA threshold for the patient must be a nonzero number.")
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
