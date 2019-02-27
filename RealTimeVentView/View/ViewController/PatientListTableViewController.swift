//
//  PatientListTableViewController.swift
//  RealTimeVentView
//
//  Created by Tony Woo on 1/30/19.
//  Copyright © 2019 CCIL. All rights reserved.
//

import UIKit

enum AccessType {
    case alert, view
}

class PatientListTableViewController: UITableViewController {

    var accessType: AccessType = .view
    var patients: [PatientModel] = []
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        patients = Storage.patients.compactMap({ PatientModel(with: $0) })
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
        return patients.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "patientCell") ?? UITableViewCell(style: .subtitle, reuseIdentifier: "patientCell")
        
        cell.textLabel?.text = patients[indexPath.row].name

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if accessType == .view {
            let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "chartViewController") as! ChartViewController
            viewController.patient = patients[indexPath.row]
            viewController.accessType = .main
            self.navigationController?.pushViewController(viewController, animated: true)
        }
        if accessType == .alert {
            let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "alertSettingsTableViewController") as! AlertSettingsTableViewController
            viewController.patient = patients[indexPath.row]
            viewController.index = indexPath.row
            viewController.accessType = .main
            self.navigationController?.pushViewController(viewController, animated: true)
        }
    }
    
    override func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let delete = UIContextualAction(style: .destructive, title: "Unenroll") { (action, view, success) in
            print("Disassociating row \(indexPath.row)")
            let alert = UIAlertController(title: "Disassociate Patient", message: "Would you like to disassociate patient \(self.patients[indexPath.row].name)?", preferredStyle: .alert)
            let confirm = UIAlertAction(title: "Confirm", style: .default) { (alertAction) in
                PatientModel.removePatient(at: indexPath.row) { (data, error) in
                    DispatchQueue.main.async {
                        switch((data, error)) {
                        case(.some, .none):
                            self.patients.remove(at: indexPath.row)
                            success(true)
                        case(.none, .some(let error)):
                            print(error)
                            success(false)
                            self.showAlert(withTitle: "Patient Disassociation Error", message: error.localizedDescription)
                        default: ()
                        }
                    }
                }
            }
            let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: { (alertAction) in
                success(false)
            })
            alert.addAction(confirm)
            alert.addAction(cancel)
            self.present(alert, animated: true)
        }
        delete.backgroundColor = UIColor.red
        let change = UIContextualAction(style: .normal, title: "Change RPi") { (action, view, success) in
            let alert = UIAlertController(title: "Change Raspberry Pi #", message: "Enter the Raspberry Pi # you wish to change to for patient \(self.patients[indexPath.row].name).", preferredStyle: .alert)
            alert.addTextField(configurationHandler: { (textField) in
                textField.placeholder = "rpi<number>"
                textField.text = self.patients[indexPath.row].rpi
            })
            
            let confirm = UIAlertAction(title: "Confirm", style: .default) { (alertAction) in
                let regex = try! NSRegularExpression(pattern: "^rpi[0-9]+$", options: [.caseInsensitive, .anchorsMatchLines])
                guard let textField = alert.textFields?.first, let rpi = textField.text, regex.firstMatch(in: rpi, options: [], range: NSRange(location: 0, length: rpi.count)) != nil else {
                    DispatchQueue.main.async {
                        self.showAlert(withTitle: "Change Raspberry Pi # Error", message: "The Raspberry Pi # should be in the format of rpi<number>.")
                        success(false)
                    }
                    return
                }
                
                self.patients[indexPath.row].updateRPi(to: rpi, at: indexPath.row, completion: { (data, error) in
                    DispatchQueue.main.async {
                        switch((data, error)) {
                        case(.some, .none):
                            success(true)
                        case(.none, .some(let error)):
                            print(error)
                            success(false)
                            self.showAlert(withTitle: "Change Raspberry Pi # Error", message: error.localizedDescription)
                        default: ()
                        }
                    }
                })
                
            }
            
            let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: { (alertAction) in
                success(false)
            })
            
            alert.addAction(confirm)
            alert.addAction(cancel)
            self.present(alert, animated: true)
            print("Changing RPi# at row \(indexPath.row)")
        }
        change.backgroundColor = UIColor.gray
        
        return UISwipeActionsConfiguration(actions: [delete, change])
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
