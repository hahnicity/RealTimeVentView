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

class AlertSettingsTableViewController: UITableViewController {
    var index = 0
    var patient = PatientModel()
    var alertSetting = AlertModel()
    var accessType: AlertAccessType = .main
    
    var alertNotification = false
    var alertTimeFrame = ""
    
    @IBOutlet weak var notificationSwitch: UISwitch!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        alertSetting = AlertModel(at: index)
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        notificationSwitch.isOn = alertSetting.notification
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0:
                let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "selectDisplayedStatsViewController") as! SelectDisplayedStatsViewController
                viewController.patient = patient
                self.navigationController?.pushViewController(viewController, animated: true)
            case 1:
                let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "alertLogsTableViewController") as! AlertLogTableViewController
                viewController.patient = patient
                self.navigationController?.pushViewController(viewController, animated: true)
            default: ()
            }
        case 1:
            if indexPath.row > 0 {
                let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "asyncAlertSettingsTableViewController") as! AsyncAlertSettingsTableViewController
                viewController.alert = alertSetting
                viewController.patient = patient
                viewController.index = index
                viewController.type = AsyncType(rawValue: indexPath.row - 1) ?? .bsa
                self.navigationController?.pushViewController(viewController, animated: true)
            }
        default: ()
        }
        
        

    }
    
    @IBAction func submit(_ sender: UIBarButtonItem) {
        let lock = NSLock()
        
        alertSetting.notification = notificationSwitch.isOn

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
                DispatchQueue.main.async {
                    let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "chartViewController") as! ChartViewController
                    viewController.patient = self.patient
                    viewController.accessType = .enroll
                    self.navigationController?.pushViewController(viewController, animated: true)
                }
            }
        }
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
