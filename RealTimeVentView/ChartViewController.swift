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

class ChartViewController: UIViewController, ChartViewDelegate {

    var patient: PatientModel = PatientModel()
    
    @IBOutlet weak var chartView: LineChartView!
    @IBOutlet weak var tviLabel: UILabel!
    @IBOutlet weak var tveLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.chartView.delegate = self
        self.navigationItem.title = patient.name
        
        let spinner = showSpinner()
        chartUpdate()
        labelUpdate()
        removeSpinner(spinner)
        // Do any additional setup after loading the view.
    }
    
    
    
    func labelUpdate() {
        let tvi = patient.getAllData(ofType: "tvi"), tve = patient.getAllData(ofType: "tve")
        tviLabel.text = "TVi: \(tvi[tvi.count - 1])"
        tveLabel.text = "TVe: \(tve[tve.count - 1])"
    }
    
    func chartUpdate() {
        patient.retrieveFlowAndPressure()
        let flow = patient.flow, pressure = patient.pressure
        var flowChartData: [ChartDataEntry] = [], pressureChartData: [ChartDataEntry] = []
        for index in 0 ..< flow.count {
            flowChartData.append(ChartDataEntry(x: Double(index) / 50.0, y: flow[index]))
            pressureChartData.append(ChartDataEntry(x: Double(index) / 50.0, y: pressure[index]))
        }
        
        let flowLine = LineChartDataSet(values: flowChartData, label: "Flow"), pressureLine = LineChartDataSet(values: pressureChartData, label: "Pressure")
        flowLine.colors = [UIColor.blue]
        flowLine.drawCirclesEnabled = false
        pressureLine.colors = [UIColor.red]
        pressureLine.drawCirclesEnabled = false
        chartView.data = LineChartData(dataSets: [flowLine, pressureLine])
        
        chartView.setVisibleXRangeMaximum(20)
        chartView.moveViewToX(Double(max((chartView.lineData?.entryCount ?? 0) / 50 - 20, 0)))
    }
    
    func loadAdditionalData() {
        let flow = patient.flow, pressure = patient.pressure
        for i in 0 ..< 1000 {
            let _  = chartView.data?.getDataSetByIndex(DataIndex.flow.rawValue)?.addEntryOrdered(ChartDataEntry(x: Double(i) / 50.0, y: flow[i]))
            let _ = chartView.data?.getDataSetByIndex(DataIndex.pressure.rawValue)?.addEntryOrdered(ChartDataEntry(x: Double(i) / 50.0, y: pressure[i]))
        }
        chartView.data?.notifyDataChanged()
        chartView.notifyDataSetChanged()
        chartView.setVisibleXRangeMaximum(20)
        chartView.moveViewToX(20)
        
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
        
        //legend[0].label = "Flow: \(flow)"
        //legend[1].label = "Pressure \(pressure)"
        
        //legend[0].label = "Flow: \(patient.flow[entry.])"
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
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

