//
//  AlertLogTableViewController.swift
//  RealTimeVentView
//
//  Created by user149673 on 5/25/19.
//  Copyright © 2019 CCIL. All rights reserved.
//

import UIKit

class AlertLogTableViewController: UITableViewController {

    var patient = PatientModel()
    var logs: [([(String, Int)], Date)] = []
    let dateFormatter = DateFormatter()
    
    var expandedCell: IndexPath?
    var detailCell: UITableViewCell?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        self.navigationItem.title = patient.name
        logs = DatabaseModel.shared.getAlerts(for: patient.name)
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
        return logs.count + (expandedCell == nil ? 0 : 1)
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.row - 1 == expandedCell?.row, let cell = detailCell {
            return cell
        }
        
        let row: Int
        if let expandedCell = expandedCell, indexPath.row > expandedCell.row {
            row = indexPath.row - 1
        }
        else {
            row = indexPath.row
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "logCell") ?? UITableViewCell(style: .default, reuseIdentifier: "logCell")
        
        cell.detailTextLabel?.text = dateFormatter.string(from: logs[row].1)
        let t = logs[row].0.map{ $0.0 }.joined(separator: ",")
        cell.textLabel?.text = t
        // Configure the cell...

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if let expandedCell = expandedCell {
            tableView.deleteRows(at: [IndexPath(row: expandedCell.row + 1, section: expandedCell.section)], with: .automatic)
            self.expandedCell = nil
            if indexPath == expandedCell {
                return
            }
        }
        // expand new cell
        let detailString = logs[indexPath.row].0.map { "\($0.0): \($0.1)" }.joined(separator: "\n")
        detailCell = tableView.dequeueReusableCell(withIdentifier: "detailCell") ?? UITableViewCell(style: .default, reuseIdentifier: "detailCell")
        detailCell?.textLabel?.text = detailString
        expandedCell = indexPath
        tableView.insertRows(at: [IndexPath(row: indexPath.row + 1, section: indexPath.section)], with: .automatic)
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
