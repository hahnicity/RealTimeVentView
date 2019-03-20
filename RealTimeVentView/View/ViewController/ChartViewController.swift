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
    var update = DispatchSemaphore(value: 1)
    var updateTimer = Timer()
    var spinner = UIView()
    static let WINDOW_WIDTH = 20.0
    static let GRANULARITY = 5.0
    
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
        DispatchQueue.main.async {
            self.updateTimer.invalidate()
            self.updateTimer = Timer()
        }
    }
    
    @IBAction func returnPressed(_ sender: UIBarButtonItem) {
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    func chartTranslated(_ chartView: ChartViewBase, dX: CGFloat, dY: CGFloat) {
        if self.chartView.lowestVisibleX == chartView.data?.xMin && dX > 50 && !updating {
            updating = true
            if self.update.wait(timeout: .now()) == .timedOut {
                DispatchQueue.global(qos: .userInitiated).async {
                    self.update.wait()
                    DispatchQueue.main.async {
                        chartView.isUserInteractionEnabled = false
                    }
                    self.loadPastData()
                }
            }
            else {
                chartView.isUserInteractionEnabled = false
                self.loadPastData()
            }
        }
    }
    
    func labelUpdate() {
        let tvi = patient.getAllData(ofType: "tvi"), tve = patient.getAllData(ofType: "tve")
        tviLabel.text = "TVi: \(tvi[tvi.count - 1])"
        tveLabel.text = "TVe: \(tve[tve.count - 1])"
    }
    
    func loadChart() {
        self.showSpinner()
        patient.loadBreaths { (flow, pressure, offsets, error) in
            if let error = error {
                self.showAlert(withTitle: "Chart Load Error", message: error.localizedDescription)
                return
            }
            
            guard let refDate = self.patient.refDate, flow.count > 0 else {
                print("No Data")
                DispatchQueue.main.async {
                    self.removeSpinner(self.spinner)
                    self.updating = false
                    /*
                    self.updateTimer = Timer.scheduledTimer(withTimeInterval: Double(Storage.updateInterval), repeats: true, block: { (timer) in
                        print("Crashed here")
                        if self.update.wait(timeout: .now()) == .success {
                            self.updateChart()
                        }
                    })
                     */
                    
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
                self.removeSpinner(self.spinner)
                self.updating = false
                self.updateTimer = Timer.scheduledTimer(withTimeInterval: Double(Storage.updateInterval), repeats: true, block: { (timer) in
                    if self.update.wait(timeout: .now()) == .success {
                        self.updateChart()
                    }
                })
            }
        }
    }
    
    func updateChart() {
        updating = true
        patient.loadNewBreaths { (flow, pressure, offsets, error) in
            if let error = error {
                self.showAlert(withTitle: "Chart Update Error", message: error.localizedDescription)
                self.updating = false
                return
            }
            
            if flow.count == 0 {
                self.updating = false
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
                self.chartView.setVisibleXRangeMaximum(ChartViewController.WINDOW_WIDTH)
                self.labelUpdate()
                if self.chartView.highestVisibleX == xMax {
                    print("Currently viewing the highest X")
                    self.chartView.moveViewToX(self.chartView.chartXMax)
                }
                self.updating = false
                self.update.signal()
            }
        }
    }
    
    func loadPastData() {
        self.showSpinner()
        patient.loadPastBreaths { (flow, pressure, offsets, error) in
            if let error = error {
                self.removeSpinner(self.spinner)
                self.showAlert(withTitle: "Past Data Load Error", message: error.localizedDescription)
                self.updating = false
                self.update.signal()
                return
            }
            
            guard flow.count > 0 else {
                print("No Data")
                DispatchQueue.main.async {
                    self.removeSpinner(self.spinner)
                    self.chartView.isUserInteractionEnabled = true
                    self.updating = false
                }
                return
            }
            
            print("Loading \(flow.count) data")
            print(offsets[0..<200])
            print(offsets[flow.count-10..<flow.count])
            let xMin = self.chartView.chartXMin
            
            for (offsetValue, (flowValue, pressureValue)) in zip(offsets, zip(flow, pressure)) {
                let _ = self.chartView.lineData?.getDataSetByLabel("Flow", ignorecase: false)?.addEntryOrdered(ChartDataEntry(x: offsetValue, y: flowValue))
                let _ = self.chartView.lineData?.getDataSetByLabel("Pressure", ignorecase: false)?.addEntryOrdered(ChartDataEntry(x: offsetValue, y: pressureValue))
            }
            
            DispatchQueue.main.async {
                print("Now applying changes")
                self.chartView.data?.notifyDataChanged()
                self.chartView.notifyDataSetChanged()
                self.chartView.setVisibleXRangeMaximum(ChartViewController.WINDOW_WIDTH)
                self.chartView.moveViewToX(xMin)
                self.chartView.isUserInteractionEnabled = true
                self.removeSpinner(self.spinner)
                self.updating = false
                self.update.signal()
            }
        }
    }
    
    func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
       //loadAdditionalData()
        if chartView.marker == nil {
            let marker = BalloonMarker(color: UIColor.gray, font: UIFont(name: "Helvetica", size: 14)!, textColor: UIColor.white, insets: UIEdgeInsets(top: 5.0, left: 5.0, bottom: 5.0, right: 5.0))
            marker.minimumSize = CGSize(width: 100.0, height: 180.0)
            marker.chartView = chartView
            chartView.marker = marker
        }
        (chartView.marker as? BalloonMarker)?.data = patient
        chartView.marker?.refreshContent(entry: entry, highlight: highlight)
    }
    /*
     
     */
    
    func showSpinner() {
        DispatchQueue.main.async {
            self.spinner = UIView.init(frame: self.view.bounds)
            self.spinner.backgroundColor = UIColor.init(red: 0.5, green: 0.5, blue:0.5, alpha: 0.5)
            let activity = UIActivityIndicatorView.init(style: .whiteLarge)
            activity.startAnimating()
            activity.center = self.spinner.center
            self.spinner.addSubview(activity)
            self.view.addSubview(self.spinner)
        }
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
