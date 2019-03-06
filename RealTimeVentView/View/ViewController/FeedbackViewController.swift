//
//  FeedbackViewController.swift
//  RealTimeVentView
//
//  Created by user149673 on 3/3/19.
//  Copyright © 2019 CCIL. All rights reserved.
//

import UIKit
import Charts

enum Classification {
    case dta, bsa, norm, none
}

class FeedbackViewController: UIViewController, ChartViewDelegate, UITableViewDelegate, UITableViewDataSource {
    
    
    @IBOutlet weak var chartView: LineChartView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var submitButton: UIBarButtonItem!
    
    var patient = PatientModel()
    var startTime = Date()
    var endTime = Date()
    var classification: [Classification] = [Classification](repeating: .none, count: Storage.numFeedbackBreaths)
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.chartView.delegate = self
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.navigationItem.hidesBackButton = true

        loadChart()
        // Do any additional setup after loading the view.
    }
    
    @IBAction func submitPressed(_ sender: UIBarButtonItem) {
        let id = patient.getBreathID()
        let breaths = zip(id, classification).map { (id, classification) -> [String: Any] in
            var val: [String: Any] = [:]
            switch classification {
            case .dta: val["classification"] = "dta"
            case .bsa: val["classification"] = "bsa"
            case .norm: val["classification"] = "norm"
            default: ()
            }
            val["id"] = id
            return val
        }
        print(["patient": patient.name, "breaths": breaths])
        ServerModel.shared.feedback(with: ["patient": patient.name, "breaths": breaths]) { (data, error) in
            switch((data, error)) {
            case(.some(let data), .none):
                DispatchQueue.main.async {
                    self.navigationController?.popViewController(animated: true)
                }
            case(.none, .some(let error)):
                self.showAlert(withTitle: "Feedback Error", message: error.localizedDescription)
            default: ()
            }
        }
    }
    
    func checkAllClassified() {
        for breath in classification {
            if breath == .none {
                return
            }
        }
        submitButton.isEnabled = true
    }
    
    func loadChart() {
        let spinner = self.showSpinner()
        
        patient.loadBreaths(between: startTime, and: endTime.addingTimeInterval(1)) { (flow, pressure, offsets, error) in
        //patient.loadJSON { (flow, pressure, offsets, error) in
            if let error = error {
                self.showAlert(withTitle: "Chart Load Error", message: error.localizedDescription)
                return
            }
            print(flow.count)
            
            guard let refDate = self.patient.refDate, flow.count > 0 else {
                print("No Data")
                DispatchQueue.main.async {
                    self.removeSpinner(spinner)
                }
                return
            }
            
            var flowChartData: [ChartDataEntry] = [], pressureChartData: [ChartDataEntry] = []
            for (offsetValue, (flowValue, pressureValue)) in zip(offsets, zip(flow, pressure)) {
                flowChartData.append(ChartDataEntry(x: offsetValue, y: flowValue))
                pressureChartData.append(ChartDataEntry(x: offsetValue, y: pressureValue))
            }
            
            let flowLine = LineChartDataSet(values: flowChartData, label: "Flow"), pressureLine = LineChartDataSet(values: pressureChartData, label: "Pressure")
            flowLine.colors = [UIColor.blue]
            flowLine.drawCirclesEnabled = false
            pressureLine.colors = [UIColor.red]
            pressureLine.drawCirclesEnabled = false
            self.chartView.xAxis.valueFormatter = TimeAxisValueFormatter(forDate: refDate)
            self.chartView.xAxis.granularity = ChartViewController.GRANULARITY
            DispatchQueue.main.async {
                self.chartView.data = LineChartData(dataSets: [flowLine, pressureLine])
                self.chartView.setVisibleXRangeMaximum(ChartViewController.WINDOW_WIDTH)
                self.chartView.moveViewToX(self.chartView.chartXMax)
                self.removeSpinner(spinner)
            }
        }
    }
    
    func showSpinner() -> UIView {
        let spinner = UIView.init(frame: self.view.bounds)
        spinner.backgroundColor = UIColor.init(red: 0.5, green: 0.5, blue:0.5, alpha: 0.5)
        let activity = UIActivityIndicatorView.init(style: .whiteLarge)
        activity.startAnimating()
        activity.center = spinner.center
        
        DispatchQueue.main.async {
            spinner.addSubview(activity)
            self.view.addSubview(spinner)
        }
        
        return spinner
    }
    
    func removeSpinner(_ spinner: UIView) {
        DispatchQueue.main.async {
            spinner.removeFromSuperview()
        }
    }
    
    func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        //loadAdditionalData()
        guard let t1 = chartView.data?.dataSets[0].entryIndex(entry: entry), let t2 = chartView.data?.dataSets[1].entryIndex(entry: entry) else {
            print("Point not identified")
            return
        }
        let index = t1 + t2 + 1
        if chartView.marker == nil {
            let marker = BalloonMarker(color: UIColor.gray, font: UIFont(name: "Helvetica", size: 14)!, textColor: UIColor.white, insets: UIEdgeInsets(top: 5.0, left: 5.0, bottom: 5.0, right: 5.0))
            marker.minimumSize = CGSize(width: 100.0, height: 170.0)
            marker.chartView = chartView
            chartView.marker = marker
        }
        (chartView.marker as? BalloonMarker)?.data = patient
        chartView.marker?.refreshContent(entry: entry, highlight: highlight)
        self.showClassificationActions(for: patient.breathIndex[index])
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.chartView.highlightValue(nil, callDelegate: false)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Storage.numFeedbackBreaths
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "breathCell", for: indexPath)
        cell.textLabel?.text = "Breath #\(indexPath.row + 1)"
        switch classification[indexPath.row] {
        case .bsa:
            cell.detailTextLabel?.text = "BSA"
        case .dta:
            cell.detailTextLabel?.text = "DTA"
        case .norm:
            cell.detailTextLabel?.text = "Normal"
        case .none:
            cell.detailTextLabel?.text = "Not Classified"
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        self.showClassificationActions(for: indexPath.row)
    }
    
    func showClassificationActions(for index: Int) {
        let alert = UIAlertController(title: "Breath #\(index + 1)", message: "Choose a classification for breath #\(index + 1)", preferredStyle: .actionSheet)
        let dta = UIAlertAction(title: "DTA", style: .default) { (action) in
            self.classification[index] = .dta
            self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
            self.chartView.highlightValue(nil, callDelegate: false)
            self.checkAllClassified()
        }
        let bsa = UIAlertAction(title: "BSA", style: .default) { (action) in
            self.classification[index] = .bsa
            self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
            self.chartView.highlightValue(nil, callDelegate: false)
            self.checkAllClassified()
        }
        let norm = UIAlertAction(title: "Normal", style: .default) { (action) in
            self.classification[index] = .norm
            self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
            self.chartView.highlightValue(nil, callDelegate: false)
            self.checkAllClassified()
        }
        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
            
        }
        alert.addAction(dta)
        alert.addAction(bsa)
        alert.addAction(norm)
        alert.addAction(cancel)
        
        self.present(alert, animated: true)
    }
    
    func showAlert(withTitle title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "Confirm", style: .cancel) { (alertAction) in
            
        }
        alert.addAction(action)
        self.present(alert, animated: true)
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
