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

class AlertSettingsTableViewController: UITableViewController, TextFieldTableViewCellDelegate {
    

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
    
    @IBOutlet weak var notificationSwitch: UISwitch!
    @IBOutlet weak var alertDTASwitch: UISwitch!
    @IBOutlet weak var thresholdDTATextField: UITextField!
    @IBOutlet weak var alertBSASwitch: UISwitch!
    @IBOutlet weak var thresholdBSATextField: UITextField!
    @IBOutlet weak var alertTVVSwitch: UISwitch!
    @IBOutlet weak var thresholdTVVTextField: UITextField!
    
    @IBOutlet var notificationControlledTableViewCells: [UITableViewCell]!
    @IBOutlet var alertDTAControlledTableViewCells: [UITableViewCell]!
    @IBOutlet var alertBSAControlledTableViewCells: [UITableViewCell]!
    @IBOutlet var alertTVVControlledTableViewCells: [UITableViewCell]!
    
    @IBOutlet weak var manageStatsCell: UITableViewCell!
    @IBOutlet weak var alertLogCell: UITableViewCell!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        alertSetting = AlertModel(at: index)
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        notificationSwitch.isOn = alertSetting.notification
        alertDTASwitch.isOn = alertSetting.alertDTA
        thresholdDTATextField.text = "\(alertSetting.thresholdDTA)"
        alertBSASwitch.isOn = alertSetting.alertBSA
        thresholdBSATextField.text = "\(alertSetting.thresholdBSA)"
        alertTVVSwitch.isOn = alertSetting.alertTVV
        thresholdTVVTextField.text = "\(alertSetting.thresholdTVV)"
        
        enableCells(in: notificationControlledTableViewCells, enable: notificationSwitch.isOn)
        if notificationSwitch.isOn {
            enableCells(in: alertDTAControlledTableViewCells, enable: alertDTASwitch.isOn)
            enableCells(in: alertBSAControlledTableViewCells, enable: alertBSASwitch.isOn)
            enableCells(in: alertTVVControlledTableViewCells, enable: alertTVVSwitch.isOn)
        }
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    
    @IBAction func notificationSwitchChanged(_ sender: UISwitch) {
        enableCells(in: notificationControlledTableViewCells, enable: sender.isOn)
        if sender.isOn {
            enableCells(in: alertDTAControlledTableViewCells, enable: alertDTASwitch.isOn)
            enableCells(in: alertBSAControlledTableViewCells, enable: alertBSASwitch.isOn)
            enableCells(in: alertTVVControlledTableViewCells, enable: alertTVVSwitch.isOn)
        }
    }
    
    @IBAction func alertDTASwitchChanged(_ sender: UISwitch) {
        enableCells(in: alertDTAControlledTableViewCells, enable: sender.isOn)
    }
    
    @IBAction func alertBSASwitchChanged(_ sender: UISwitch) {
        enableCells(in: alertBSAControlledTableViewCells, enable: sender.isOn)
    }
    
    @IBAction func alertTVVSwitchChanged(_ sender: UISwitch) {
        enableCells(in: alertTVVControlledTableViewCells, enable: sender.isOn)
    }
    
    func enableCells(in cells: [UITableViewCell], enable: Bool) {
        for cell in cells {
            cell.isUserInteractionEnabled = enable
            switch cell {
            case let switchCell as SwitchTableViewCell:
                switchCell.title.isEnabled = enable
                switchCell.alertSwitch.isEnabled = enable
            case let textCell as TextFieldTableViewCell:
                textCell.textField.isEnabled = enable
            default:
                cell.textLabel?.isEnabled = enable
            }
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
        
        switch tableView.cellForRow(at: indexPath) {
        case manageStatsCell:
            let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "selectDisplayedStatsViewController") as! SelectDisplayedStatsViewController
            viewController.patient = patient
            self.navigationController?.pushViewController(viewController, animated: true)
        case alertLogCell:
            let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "alertLogsTableViewController") as! AlertLogTableViewController
            viewController.patient = patient
            self.navigationController?.pushViewController(viewController, animated: true)
        default: ()
        }

    }
    
    @IBAction func submit(_ sender: UIBarButtonItem) {
        guard let thresholdDTA = thresholdDTATextField.text,
            let thresholdBSA = thresholdBSATextField.text,
            let thresholdTVV = thresholdTVVTextField.text else {
                print("Number not retrieved")
                return
        }
        
        if hasFormError(withDTA: thresholdDTA, BSA: thresholdBSA, TVV: thresholdTVV) {
            return
        }
        
        let lock = NSLock()
        alertSetting = AlertModel(withAlertDTA: alertDTASwitch.isOn, thresholdDTA: Int(thresholdDTA)!, alertBSA: alertBSASwitch.isOn, thresholdBSA: Int(thresholdBSA)!, alertTVV: alertTVVSwitch.isOn, thresholdTVV: Int(thresholdTVV)!, notification: notificationSwitch.isOn)

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
