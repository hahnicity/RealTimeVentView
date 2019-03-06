//
//  ChartViewController.swift
//  RealTimeVentView
//
//  Created by Tony Woo on 1/30/19.
//  Copyright © 2019 CCIL. All rights reserved.
//

import UIKit
import Charts

enum DataIndex: Int {
    case flow = 0, pressure = 1
}

enum ChartAccessType {
    case main, enroll
}

class ChartViewController: UIViewController, ChartViewDelegate {

    var patient: PatientModel = PatientModel()
    var accessType: ChartAccessType = .main
    var updating = false
    var updateTimer = Timer()
    static let WINDOW_WIDTH = 30.0
    static let GRANULARITY = 10.0
    
    @IBOutlet weak var chartView: LineChartView!
    
    
    @IBOutlet weak var returnButton: UIBarButtonItem!
    @IBOutlet weak var tviLabel: UILabel!
    @IBOutlet weak var tveLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.chartView.delegate = self
        self.navigationItem.title = patient.name
        
        switch accessType {
        case .main:
            self.navigationItem.rightBarButtonItem = nil
        case .enroll:
            self.navigationItem.hidesBackButton = true
        }
        
        loadChart()
        // Do any additional setup after loading the view.
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        updateTimer.invalidate()
    }
    
    @IBAction func returnPressed(_ sender: UIBarButtonItem) {
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    func chartTranslated(_ chartView: ChartViewBase, dX: CGFloat, dY: CGFloat) {
        if self.chartView.lowestVisibleX == chartView.data?.xMin && dX > 50 && !updating {
            print("Dragging Past Beginning")
            updating = true
            chartView.isUserInteractionEnabled = false
            loadPastData()
        }
    }
    
    func labelUpdate() {
        let tvi = patient.getAllData(ofType: "tvi"), tve = patient.getAllData(ofType: "tve")
        tviLabel.text = "TVi: \(tvi[tvi.count - 1])"
        tveLabel.text = "TVe: \(tve[tve.count - 1])"
    }
    
    func loadChart() {
        let spinner = self.showSpinner()
        patient.loadBreaths { (flow, pressure, offsets, error) in
            if let error = error {
                self.showAlert(withTitle: "Chart Load Error", message: error.localizedDescription)
                return
            }
            
            guard let refDate = self.patient.refDate, flow.count > 0 else {
                print("No Data")
                DispatchQueue.main.async {
                    self.removeSpinner(spinner)
                    self.updating = false
                    self.updateTimer = Timer.scheduledTimer(withTimeInterval: Double(Storage.updateInterval), repeats: true, block: { (timer) in
                        if self.updating == false {
                            self.updateChart()
                        }
                    })
                    
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
                self.labelUpdate()
                self.removeSpinner(spinner)
                self.updating = false
                self.updateTimer = Timer.scheduledTimer(withTimeInterval: Double(Storage.updateInterval), repeats: true, block: { (timer) in
                    if self.updating == false {
                        self.updateChart()
                    }
                })
            }
        }
    }
    
    func updateChart() {
        patient.loadNewBreaths { (flow, pressure, offsets, error) in
            if let error = error {
                self.showAlert(withTitle: "Chart Update Error", message: error.localizedDescription)
                return
            }
            
            if flow.count == 0 {
                return // no new update
            }
            
            let xMax = self.chartView.chartXMax
            
            for (offsetValue, (flowValue, pressureValue)) in zip(offsets, zip(flow, pressure)) {
                let _ = self.chartView.lineData?.getDataSetByLabel("Flow", ignorecase: false)?.addEntry(ChartDataEntry(x: offsetValue, y: flowValue))
                let _ = self.chartView.lineData?.getDataSetByLabel("Pressure", ignorecase: false)?.addEntry(ChartDataEntry(x: offsetValue, y: pressureValue))
            }
            
            DispatchQueue.main.async {
                self.chartView.data?.notifyDataChanged()
                self.chartView.notifyDataSetChanged()
                self.labelUpdate()
                if self.chartView.highestVisibleX == xMax {
                    self.chartView.moveViewToX(self.chartView.chartXMax)
                }
                self.updating = false
            }
        }
    }
    
    func loadPastData() {
        let spinner = self.showSpinner()
        patient.loadPastBreaths { (flow, pressure, offsets, error) in
            if let error = error {
                self.showAlert(withTitle: "Past Data Load Error", message: error.localizedDescription)
                return
            }
            
            let xMin = self.chartView.chartXMin
            
            for (offsetValue, (flowValue, pressureValue)) in zip(offsets, zip(flow, pressure)) {
                let _ = self.chartView.lineData?.getDataSetByLabel("Flow", ignorecase: false)?.addEntryOrdered(ChartDataEntry(x: offsetValue, y: flowValue))
                let _ = self.chartView.lineData?.getDataSetByLabel("Pressure", ignorecase: false)?.addEntryOrdered(ChartDataEntry(x: offsetValue, y: pressureValue))
            }
            
            DispatchQueue.main.async {
                self.chartView.data?.notifyDataChanged()
                self.chartView.notifyDataSetChanged()
                self.chartView.setVisibleXRangeMaximum(ChartViewController.WINDOW_WIDTH)
                self.chartView.moveViewToX(xMin)
                self.chartView.isUserInteractionEnabled = true
                self.removeSpinner(spinner)
                self.updating = false
            }
        }
    }
    
    func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
       //loadAdditionalData()
        if chartView.marker == nil {
            let marker = BalloonMarker(color: UIColor.gray, font: UIFont(name: "Helvetica", size: 14)!, textColor: UIColor.white, insets: UIEdgeInsets(top: 5.0, left: 5.0, bottom: 5.0, right: 5.0))
            marker.minimumSize = CGSize(width: 100.0, height: 170.0)
            marker.chartView = chartView
            chartView.marker = marker
        }
        (chartView.marker as? BalloonMarker)?.data = patient
        chartView.marker?.refreshContent(entry: entry, highlight: highlight)
    }
    /*
     
     */
    
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

class TimeAxisValueFormatter: IAxisValueFormatter {
    
    let dateFormatter = DateFormatter()
    var refDate: Date
    
    init(forDate refDate: Date) {
        self.refDate = refDate
        dateFormatter.dateFormat = "HH:mm:ss"
    }
    
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        return dateFormatter.string(from: Date(timeInterval: value, since: refDate))
    }
    
    
}
