//
//  TimeFrameStatsViewController.swift
//  RealTimeVentView
//
//  Created by user149673 on 5/22/19.
//  Copyright © 2019 CCIL. All rights reserved.
//

import UIKit

class TimeFrameStatsViewController: UIViewController {
    
    @IBOutlet weak var starTimeLabel: UILabel!
    @IBOutlet weak var endTimeLabel: UILabel!
    @IBOutlet weak var breathStatsTableView: UITableView!
    @IBOutlet weak var asyncStatsTableView: UITableView!
    
    var patient = PatientModel()
    var date = Date()
    var timeInterval = 0.0
    var returnPoint = UIViewController()
    
    let breathMetadataType = BREATH_STAT_METADATA
    lazy var breathMetadataStat = [String](repeating: "", count: breathMetadataType.count)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.hidesBackButton = true
        breathStatsTableView.delegate = self
        breathStatsTableView.dataSource = self
        asyncStatsTableView.delegate = self
        asyncStatsTableView.dataSource = self
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        starTimeLabel.text = dateFormatter.string(from: Date(timeInterval: -timeInterval, since: date))
        endTimeLabel.text = dateFormatter.string(from: date)
        
        let spinner = showSpinner()
        
        patient.getStats(for: timeInterval, from: date) { (stats, error) in
            if let error = error {
                self.removeSpinner(spinner)
                self.showAlert(withTitle: "Stats Calculation Error", message: error.localizedDescription)
                return
            }
            for (index, type) in self.breathMetadataType.enumerated() {
                if let stat = stats[type] {
                    self.breathMetadataStat[index] = String(format: "%.2f", stat)
                }
            }
            DispatchQueue.main.async {
                self.breathStatsTableView.reloadData()
                self.removeSpinner(spinner)
            }
        }
        // Do any additional setup after loading the view.
    }
    
    @IBAction func exit(_ sender: UIBarButtonItem) {
        self.navigationController?.popToViewController(returnPoint, animated: true)
    }
    
    func showAlert(withTitle title: String, message: String) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            let action = UIAlertAction(title: "Confirm", style: .cancel) { (alertAction) in
                
            }
            alert.addAction(action)
            self.present(alert, animated: true)
        }
    }
    
    func showSpinner() -> UIView {
        let spinner = UIView.init(frame: self.view.bounds)
        DispatchQueue.main.async {
            spinner.backgroundColor = UIColor.init(red: 0.5, green: 0.5, blue:0.5, alpha: 0.5)
            let activity = UIActivityIndicatorView.init(style: .whiteLarge)
            activity.startAnimating()
            activity.center = spinner.center
            spinner.addSubview(activity)
            self.view.addSubview(spinner)
            print("showing spinner...")
        }
        return spinner
    }
    
    func removeSpinner(_ spinner: UIView) {
        DispatchQueue.main.async {
            spinner.removeFromSuperview()
            print("removing spinner...")
        }
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension TimeFrameStatsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if tableView == breathStatsTableView {
            return "Metadata Stats"
        }
        else if tableView == asyncStatsTableView {
            
        }
        return ""
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == breathStatsTableView {
            return breathMetadataType.count
        }
        else if tableView == asyncStatsTableView {
            
        }
        
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "statsCell") ?? UITableViewCell(style: .default, reuseIdentifier: "statsCell")
        if tableView == breathStatsTableView {
            cell.textLabel?.text = breathMetadataType[indexPath.row]
            cell.detailTextLabel?.text = breathMetadataStat[indexPath.row]
        }
        else if tableView == asyncStatsTableView {
            
        }
        
        return cell
    }
    
    
}
