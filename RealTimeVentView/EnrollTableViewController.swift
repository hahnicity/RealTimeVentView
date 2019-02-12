//
//  EnrollTableViewController.swift
//  RealTimeVentView
//
//  Created by user149673 on 2/11/19.
//  Copyright © 2019 CCIL. All rights reserved.
//

import UIKit

enum EnrollCellType {
    case label, textField, picker, button
}

class EnrollTableViewController: UITableViewController, PickerTableViewCellDelegate, ButtonTableViewCellDelegate {
    
    var cellTypes: [EnrollCellType] = [.label, .textField, .label, .textField, .label, .label, .textField, .label, .textField, .button]
    var cellTitles = ["Name", "", "Age", "", "Sex", "Height (cm)", "", "Raspberry Pi #", "", ""]
    let sex = ["Male", "Female"]
    
    var pickerIndex: IndexPath?
    
    override func viewDidLoad() {
        super.viewDidLoad()

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
        print(cellTypes.count + (pickerIndex == nil ? 0 : 1))
        return cellTypes.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if pickerIndex == indexPath {
            let cell = (tableView.dequeueReusableCell(withIdentifier: "pickerCell") ?? UITableViewCell(style: .default, reuseIdentifier: "pickerCell")) as! PickerTableViewCell
            
            cell.delegate = self
            return cell
        }
        else {
            if cellTypes[indexPath.row] == .label {
                let cell = (tableView.dequeueReusableCell(withIdentifier: "labelCell") ?? UITableViewCell(style: .subtitle, reuseIdentifier: "labelCell"))
                cell.textLabel?.text = cellTitles[indexPath.row]
                cell.detailTextLabel?.text = ""
                if cellTitles[indexPath.row] == "Sex" {
                    cell.detailTextLabel?.text = "Not Specified"
                }
                return cell
            }
            else if cellTypes[indexPath.row] == .button {
                let cell = (tableView.dequeueReusableCell(withIdentifier: "buttonCell") ?? UITableViewCell(style: .default, reuseIdentifier: "buttonCell")) as! ButtonTableViewCell
                cell.delegate = self
                return cell
            }
            else {
                let cell = (tableView.dequeueReusableCell(withIdentifier: "textFieldCell") ?? UITableViewCell(style: .default, reuseIdentifier: "textFieldCell")) as! TextFieldTableViewCell
                return cell
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        self.view.endEditing(true)
        
        if let index = pickerIndex {
            tableView.cellForRow(at: IndexPath(row: index.row - 1, section: index.section))?.detailTextLabel?.text = sex[(tableView.cellForRow(at: index) as! PickerTableViewCell).index]
            pickerIndex = nil
            cellTypes.remove(at: index.row)
            cellTitles.remove(at: index.row)
            tableView.deleteRows(at: [index], with: .automatic)
        }
        else if cellTitles[indexPath.row] == "Sex" {
            pickerIndex = IndexPath(row: indexPath.row + 1, section: indexPath.section)
            cellTypes.insert(.picker, at: pickerIndex!.row)
            cellTitles.insert("", at: pickerIndex!.row)
            tableView.insertRows(at: [pickerIndex!], with: .automatic)
        }
        
        /*
        if cellTitles[indexPath.row] == "Sex" {
            if let index = pickerIndex {
                tableView.cellForRow(at: indexPath)?.detailTextLabel?.text = sex[(tableView.cellForRow(at: index) as! PickerTableViewCell).index]
                pickerIndex = nil
                cellTypes.remove(at: index.row)
                cellTitles.remove(at: index.row)
                tableView.deleteRows(at: [index], with: .automatic)
            }
            else {
                pickerIndex = IndexPath(row: indexPath.row + 1, section: indexPath.section)
                cellTypes.insert(.picker, at: pickerIndex!.row)
                cellTitles.insert("", at: pickerIndex!.row)
                tableView.insertRows(at: [pickerIndex!], with: .automatic)
            }
        }
         */
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    func selectSex(atIndex index: Int) {
        if let pickerIndex = pickerIndex {
            let sexCellIndex = tableView.cellForRow(at: IndexPath(row: pickerIndex.row - 1, section: pickerIndex.section))
            sexCellIndex?.detailTextLabel?.text = sex[index]
        }
    }
    
    func submitForm() {
        guard let name = (tableView.cellForRow(at: IndexPath(row: 1, section: 0)) as? TextFieldTableViewCell)?.textField.text,
            let age = (tableView.cellForRow(at: IndexPath(row: 3, section: 0)) as? TextFieldTableViewCell)?.textField.text,
            let sex = tableView.cellForRow(at: IndexPath(row: 4, section: 0))?.detailTextLabel?.text,
            let height = (tableView.cellForRow(at: IndexPath(row: 6 + (pickerIndex == nil ? 0 : 1), section: 0)) as? TextFieldTableViewCell)?.textField.text,
            let rpi = (tableView.cellForRow(at: IndexPath(row: 8 + (pickerIndex == nil ? 0 : 1), section: 0)) as? TextFieldTableViewCell)?.textField.text else {
                print("Enroll form error")
            return
        }
        print("text: \(sex)")
        if hasFormError(withName: name, age: age, sex: sex, height: height, rpi: rpi) {
            return
        }
        
        Storage.enrolledName.append(name)
        Storage.alertBSA.append(Storage.defaultAlertBSA)
        Storage.thresholdBSA.append(Storage.defaultThresholdBSA)
        Storage.alertDTA.append(Storage.defaultAlertDTA)
        Storage.thresholdDTA.append(Storage.defaultThresholdDTA)
        
        let transition = UIAlertController(title: "Alert", message: "Would you like to configure the alert setting for this patient?", preferredStyle: .alert)
        let yes = UIAlertAction(title: "Yes", style: .default) { (alertAction) in
            let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "alertSettingsTableViewController") as! AlertSettingsTableViewController
            viewController.patient = PatientModel(withName: Storage.enrolledName[Storage.enrolledName.count - 1])
            viewController.index = Storage.enrolledName.count - 1
            viewController.accessType = .enroll
            self.navigationController?.pushViewController(viewController, animated: true)
        }
        let no = UIAlertAction(title: "No", style: .default) { (alertAction) in
            let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "chartViewController") as! ChartViewController
            viewController.patient = PatientModel(withName: Storage.enrolledName[Storage.enrolledName.count - 1])
            self.navigationController?.pushViewController(viewController, animated: true)
        }
        transition.addAction(no)
        transition.addAction(yes)
        self.present(transition, animated: true)
    }
    
    func hasFormError(withName name: String, age: String, sex: String, height: String, rpi: String) -> Bool {
        if name.count == 0 {
            showAlert(withTitle: "Submission Error", message: "Please enter the name of the patient.")
            return true
        }
        if age.count == 0 {
            showAlert(withTitle: "Submission Error", message: "Please enter the age of the patient.")
            return true
        }
        if sex == "Not Specified" {
            showAlert(withTitle: "Submission Error", message: "Please select the sex of the patient.")
            return true
        }
        if height.count == 0 {
            showAlert(withTitle: "Submission Error", message: "Please enter the height of the patient.")
            return true
        }
        if rpi.count == 0 {
            showAlert(withTitle: "Submission Error", message: "Please enter the Raspberry Pi # of the patient.")
            return true
        }
        guard let _ = Int(age) else {
            showAlert(withTitle: "Submission Error", message: "The age of the patient must be a number.")
            return true
        }
        guard let _ = Int(height) else {
            showAlert(withTitle: "Submission Error", message: "The height of the patient must be a number.")
            return true
        }
        guard let _ = Int(rpi) else {
            showAlert(withTitle: "Submission Error", message: "The Raspberry Pi # of the patient must be a number.")
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
