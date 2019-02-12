//
//  ConfigurationTableViewController.swift
//  RealTimeVentView
//
//  Created by user149673 on 2/11/19.
//  Copyright © 2019 CCIL. All rights reserved.
//

import UIKit

enum ConfigType {
    case label, textField
}

class ConfigurationTableViewController: UITableViewController, ButtonTableViewCellDelegate {
    

    var alertCellTypes: [AlertSettingType] = [.alertSwitch, .label, .textField, .alertSwitch, .label, .textField, .button]
    var alertCellTitles = ["Alert for DTA", "DTA Threshold Past Hour", "", "Alert for BSA", "BSA Threshold Past Hour", "", ""]
    
    var configCellTypes: [ConfigType] = [.label, .textField]
    var configCellTitles = ["Update Interval (seconds)", ""]
    
    var sectionHeaders = ["App Configuration", "Default Alert Settings"]
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

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
        else {
            let cell = (tableView.dequeueReusableCell(withIdentifier: "textFieldCell") ?? UITableViewCell(style: .default, reuseIdentifier: "textFieldCell")) as! TextFieldTableViewCell
            switch(indexPath.row) {
            case 1:
                cell.textField.text = "\(Storage.updateInterval)"
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
            switch(indexPath.row) {
            case 0:
                cell.alertSwitch.isOn = Storage.defaultAlertDTA
            case 3:
                cell.alertSwitch.isOn = Storage.defaultAlertBSA
            default: ()
            }
            return cell
        }
        else {
            let cell = (tableView.dequeueReusableCell(withIdentifier: "textFieldCell") ?? UITableViewCell(style: .default, reuseIdentifier: "textFieldCell")) as! TextFieldTableViewCell
            switch(indexPath.row) {
            case 2:
                cell.textField.text = "\(Storage.defaultThresholdDTA)"
            case 5:
                cell.textField.text = "\(Storage.defaultThresholdBSA)"
            default: ()
            }
            return cell
        }
    }
    
    func submitForm() {
        guard let updateInterval = (tableView.cellForRow(at: IndexPath(row: 1, section: 0)) as? TextFieldTableViewCell)?.textField.text,
            let dtaOn = (tableView.cellForRow(at: IndexPath(row: 0, section: 1)) as? SwitchTableViewCell)?.alertSwitch.isOn,
            let dta = (tableView.cellForRow(at: IndexPath(row: 2, section: 1)) as? TextFieldTableViewCell)?.textField.text,
            let bsaOn = (tableView.cellForRow(at: IndexPath(row: 3, section: 1)) as? SwitchTableViewCell)?.alertSwitch.isOn,
            let bsa = (tableView.cellForRow(at: IndexPath(row: 5, section: 1)) as? TextFieldTableViewCell)?.textField.text else {
                print("Data Read Error")
                return
        }
        
        if hasAppConfigError(withUpdateInterval: updateInterval) || hasDefaultSettingsError(withDTA: dta, BSA: bsa) {
            return
        }
        
        Storage.updateInterval = Int(updateInterval)!
        Storage.defaultAlertDTA = dtaOn
        Storage.defaultThresholdDTA = Int(dta)!
        Storage.defaultAlertBSA = bsaOn
        Storage.defaultThresholdBSA = Int(bsa)!
        
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    func hasDefaultSettingsError(withDTA dta: String, BSA bsa: String) -> Bool {
        if dta.count == 0 {
            showAlert(withTitle: "Default Alert Settings Error", message: "Please enter the DTA thrshold for the patient.")
            return true
        }
        if bsa.count == 0 {
            showAlert(withTitle: "Default Alert Settings Error", message: "Please enter the BSA thrshold for the patient.")
            return true
        }
        guard let temp_dta = Int(dta) else {
            showAlert(withTitle: "Default Alert Settings Error", message: "The DTA threshold for the patient must be a nonzero number.")
            return true
        }
        
        if temp_dta == 0 {
            showAlert(withTitle: "Default Alert Settings Error", message: "The DTA threshold for the patient must be a nonzero number.")
            return true
        }
        
        guard let temp_bsa = Int(bsa) else {
            showAlert(withTitle: "Default Alert Settings Error", message: "The BSA threshold for the patient must be a nonzero number.")
            return true
        }
        
        if temp_bsa == 0 {
            showAlert(withTitle: "Default Alert Settings Error", message: "The BSA threshold for the patient must be a nonzero number.")
            return true
        }
        
        return false
    }
    
    func hasAppConfigError(withUpdateInterval updateInterval: String) -> Bool {
        if updateInterval.count == 0 {
            showAlert(withTitle: "App Configuration Error", message: "Please enter the time interval of the view update.")
            return true
        }
        
        guard let temp_ui = Int(updateInterval) else {
            showAlert(withTitle: "App Configuration Error", message: "The update interval should be a nonzero number.")
            return true
        }
        
        if temp_ui == 0 {
            showAlert(withTitle: "App Configuration Error", message: "The update interval should be a nonzero number.")
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
