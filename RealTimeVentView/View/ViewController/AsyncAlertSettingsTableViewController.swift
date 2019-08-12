//
//  AsyncAlertSettingsTableViewController.swift
//  RealTimeVentView
//
//  Created by user149673 on 5/28/19.
//  Copyright © 2019 CCIL. All rights reserved.
//

import UIKit



class AsyncAlertSettingsTableViewController: UITableViewController {
    
    @IBOutlet weak var alertLabel: UILabel!
    @IBOutlet weak var alertSwitch: UISwitch!
    
    @IBOutlet weak var lowerThresholdFrequencyLabel: UILabel!
    @IBOutlet weak var lowerThresholdFrequencyTextField: UITextField!
    @IBOutlet weak var thresholdFrequencyLabel: UILabel!
    @IBOutlet weak var thresholdFrequencyTextField: UITextField!
    @IBOutlet weak var timeFrameLabel: UILabel!
    @IBOutlet weak var timeFrameTextField: UITextField!
    @IBOutlet weak var alertDurationLabel: UILabel!
    @IBOutlet weak var alertDurationTextField: UITextField!
    
    @IBOutlet weak var alertDurationCell: UITableViewCell!
    
    var index: Int?
    var type: AsyncType = .bsa
    var patient: PatientModel?
    var alert = AlertModel()
    
    let alertDurationType: [AsyncType] = [ .rr , .tvi, .mv, .maw]
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tableTapped))
        tableView.addGestureRecognizer(tapGesture)
        
        self.navigationItem.title = "\(type.string) Alerts"
        alertLabel.text = "Alert for \(type.string)"
        let alertType: AsynchronyAlertModel
        switch type {
        case .bsa:
            alertType = alert.alertBSA
        case .dta:
            alertType = alert.alertDTA
        case .tvv:
            alertType = alert.alertTVV
        case .rr:
            alertType = alert.alertRR
        case .tvi:
            alertType = alert.alertTVI
        case .maw:
            alertType = alert.alertMAW
        case .mv:
            alertType = alert.alertMV
        }
        
        alertSwitch.isOn = alertType.alert
        thresholdFrequencyTextField.text = "\(alertType.thresholdFrequency)"
        lowerThresholdFrequencyTextField.text = "\(alertType.lowerThreshold)"
        timeFrameTextField.text = "\(alertType.timeFrame)"
        alertDurationTextField.text = alertType.alertDuration == nil ? "" : "\(alertType.alertDuration!)"
        
        if !alertDurationType.contains(type) {
            //alertDurationCell.isHidden = true
            alertDurationLabel.isHidden = true
            alertDurationTextField.isHidden = true
            lowerThresholdFrequencyLabel.isHidden = true
            lowerThresholdFrequencyTextField.isHidden = true
        }

        turnCellsOn(alertType.alert)
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    
    @IBAction func switchChanged(_ sender: UISwitch) {
        turnCellsOn(sender.isOn)
    }
    
    func turnCellsOn(_ on: Bool) {
        lowerThresholdFrequencyLabel.isEnabled = on
        lowerThresholdFrequencyTextField.isEnabled = on
        thresholdFrequencyLabel.isEnabled = on
        thresholdFrequencyTextField.isEnabled = on
        timeFrameLabel.isEnabled = on
        timeFrameTextField.isEnabled = on
        alertDurationLabel.isEnabled = on
        alertDurationTextField.isEnabled = on
    }
    
    @IBAction func submit(_ sender: UIBarButtonItem) {
        guard let thresholdFrequency = thresholdFrequencyTextField.text,
            let lowerThresholdFrequency = lowerThresholdFrequencyTextField.text,
            let timeFrame = timeFrameTextField.text,
            let alertDuration = alertDurationTextField.text else {
            return
        }
        
        if hasFormError(WithThresholdFrequency: thresholdFrequency, withLowerThresholdFrequency: lowerThresholdFrequency, withAlertDuration: alertDuration, WithinTimeFrame: timeFrame) {
            return
        }
        
        switch type {
        case .bsa:
            alert.alertBSA = AsynchronyAlertModel(forType: .bsa, setTo: alertSwitch.isOn, withThresholdFrequencyOf: Int(thresholdFrequency)!, withLowerThresholFrequency: -1, withinTimeFrame: Int(timeFrame)!)
        case .dta:
            alert.alertDTA = AsynchronyAlertModel(forType: .dta, setTo: alertSwitch.isOn, withThresholdFrequencyOf: Int(thresholdFrequency)!, withLowerThresholFrequency: -1, withinTimeFrame: Int(timeFrame)!)
        case .tvv:
            alert.alertTVV = AsynchronyAlertModel(forType: .tvv, setTo: alertSwitch.isOn, withThresholdFrequencyOf: Int(thresholdFrequency)!, withLowerThresholFrequency: -1, withinTimeFrame: Int(timeFrame)!)
        case .rr:
            alert.alertRR = AsynchronyAlertModel(forType: .rr, setTo: alertSwitch.isOn, withThresholdFrequencyOf: Int(thresholdFrequency)!, withLowerThresholFrequency: Int(lowerThresholdFrequency)!, withAlertDurationOf: Int(alertDuration), withinTimeFrame: Int(timeFrame)!)
        case .mv:
            alert.alertMV = AsynchronyAlertModel(forType: .mv, setTo: alertSwitch.isOn, withThresholdFrequencyOf: Int(thresholdFrequency)!, withLowerThresholFrequency: Int(lowerThresholdFrequency)!, withAlertDurationOf: Int(alertDuration), withinTimeFrame: Int(timeFrame)!)
        case .tvi:
            alert.alertTVI = AsynchronyAlertModel(forType: .tvi, setTo: alertSwitch.isOn, withThresholdFrequencyOf: Int(thresholdFrequency)!, withLowerThresholFrequency: Int(lowerThresholdFrequency)!, withAlertDurationOf: Int(alertDuration), withinTimeFrame: Int(timeFrame)!)
        case .maw:
            alert.alertMAW = AsynchronyAlertModel(forType: .maw, setTo: alertSwitch.isOn, withThresholdFrequencyOf: Int(thresholdFrequency)!, withLowerThresholFrequency: Int(lowerThresholdFrequency)!, withAlertDurationOf: Int(alertDuration), withinTimeFrame: Int(timeFrame)!)
        }
        
        // THIS IS ONLY HERE UNTIL WE IMPLEMENT A SEPERATE TIME FRAME FOR EACH ASYNCHRONY
        alert.alertBSA.timeFrame = Int(timeFrame)!
        alert.alertDTA.timeFrame = Int(timeFrame)!
        alert.alertTVV.timeFrame = Int(timeFrame)!
        alert.alertRR.timeFrame = Int(timeFrame)!
        alert.alertMV.timeFrame = Int(timeFrame)!
        alert.alertMAW.timeFrame = Int(timeFrame)!
        alert.alertTVI.timeFrame = Int(timeFrame)!
        
        if let patient = patient, let index = index {
            let lock = NSLock()
            lock.lock()
            alert.update(for: patient, at: index) { (data, error) in
                if let error = error {
                    self.showAlert(withTitle: "Alert Update Error", message: error.localizedDescription)
                    lock.unlock()
                    return
                }
                lock.unlock()
            }
            lock.lock()
        }
        else {
            Storage.defaultAlert = alert.json
        }
        
        self.navigationController?.popViewController(animated: true)
        
    }
    
    
    func hasFormError(WithThresholdFrequency thresholdFrequency: String, withLowerThresholdFrequency lowerThresholdFrequency: String, withAlertDuration alertDuration: String, WithinTimeFrame timeFrame: String) -> Bool {
        if thresholdFrequency.count == 0 {
            showAlert(withTitle: "Alert Settings Error", message: "Please enter the threshold frequency for the patient.")
            return true
        }
        
        if thresholdFrequency.count == 0 && type == .rr {
            showAlert(withTitle: "Alert Settings Error", message: "Please enter the alert duration for the patient.")
            return true
        }
        
        if lowerThresholdFrequency.count == 0 {
            showAlert(withTitle: "Alert Settings Error", message: "Please enter the lower threshold frequency for the patient.")
            return true
        }

        if timeFrame.count == 0 {
            showAlert(withTitle: "Alert Settings Error", message: "Please enter the threshold frequency for the patient.")
            return true
        }
        
        guard let freq = Int(thresholdFrequency), freq > 0 else {
            showAlert(withTitle: "Alert Settings Error", message: "The threshold frequency must be a positive number.")
            return true
        }
        
        guard let lowerFreq = Int(lowerThresholdFrequency), lowerFreq > 0 else {
            showAlert(withTitle: "Alert Settings Error", message: "The lower threshold frequency must be a positive number.")
            return true
        }
        
        if lowerFreq >= freq {
            showAlert(withTitle: "Alert Settings Error", message: "The lower threshold must be a smaller value than the threshold.")
            return true
        }
        
        if alertDurationType.contains(type) {
            guard let duration = Int(alertDuration), duration > 0 else {
                showAlert(withTitle: "Alert Settings Error", message: "The alert duration must be a positive number.")
                return true
            }
        }
        
        guard let time = Int(timeFrame), time > 0 else {
            showAlert(withTitle: "Alert Settings Error", message: "The time frame must be a positive number.")
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
    
    @objc func tableTapped() {
        self.view.endEditing(true)
    }

    // MARK: - Table view data source

    /*
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 0
    }
     */

    /*
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...

        return cell
    }
    */

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
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
