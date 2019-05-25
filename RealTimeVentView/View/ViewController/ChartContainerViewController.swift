//
//  ChartContainerViewController.swift
//  RealTimeVentView
//
//  Created by user149673 on 5/22/19.
//  Copyright © 2019 CCIL. All rights reserved.
//

import UIKit

class ChartContainerViewController: UIViewController {

    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        var chartNavigationController: UINavigationController
        var chartViewController: ChartViewController!
        
        chartViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "chartViewController") as! ChartViewController
        chartNavigationController = UINavigationController(rootViewController: chartViewController)
        chartNavigationController.didMove(toParent: self)
        
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


