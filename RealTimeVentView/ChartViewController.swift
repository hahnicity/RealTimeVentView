//
//  ChartViewController.swift
//  RealTimeVentView
//
//  Created by Tony Woo on 1/30/19.
//  Copyright © 2019 CCIL. All rights reserved.
//

import UIKit

class ChartViewController: UIViewController {

    var patient: PatientModel = PatientModel()
    var json: [String: Any] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let json = patient.getPatientData() else {
            return
        }
        
        self.json = json
        // Do any additional setup after loading the view.
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
