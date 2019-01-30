//
//  ViewController.swift
//  RealTimeVentView
//
//  Created by Gregory Rehm on 1/29/19.
//  Copyright © 2019 CCIL. All rights reserved.
//

import UIKit

class MainViewController: UIViewController {


    @IBOutlet var mainButtons: [UIButton]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        for button in mainButtons {
            button.layer.borderColor = button.titleLabel?.textColor.cgColor
            button.titleLabel?.minimumScaleFactor = 0.1
            button.titleLabel?.adjustsFontSizeToFitWidth = true
        }
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    @IBAction func viewPressed(_ sender: UIButton) {
        let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "patientListTableViewController") as! PatientListTableViewController
        self.navigationController?.pushViewController(viewController, animated: true)
    }
    
    @IBAction func enrollPressed(_ sender: UIButton) {
        let list = ["Patient A", "Patient B"]
        Storage.enrolled = list
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

