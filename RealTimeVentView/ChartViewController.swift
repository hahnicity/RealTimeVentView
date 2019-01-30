//
//  ChartViewController.swift
//  RealTimeVentView
//
//  Created by Tony Woo on 1/30/19.
//  Copyright © 2019 CCIL. All rights reserved.
//

import UIKit
import Charts

class ChartViewController: UIViewController {

    var patient: PatientModel = PatientModel()
    
    @IBOutlet weak var chartView: LineChartView!
    @IBOutlet weak var tviLabel: UILabel!
    @IBOutlet weak var tveLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = patient.name
        
        labelUpdate()
        chartUpdate()
        // Do any additional setup after loading the view.
    }
    
    
    
    func labelUpdate() {
        let tvi = patient.getAllData(ofType: "tvi"), tve = patient.getAllData(ofType: "tve")
        tviLabel.text = "TVi: \(tvi[tvi.count - 1])"
        tveLabel.text = "TVe: \(tve[tve.count - 1])"
    }
    
    func chartUpdate() {
        let (flow, pressure) = patient.getFlowAndPressure()
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
