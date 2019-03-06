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
        
        if Storage.numFeedbackBreaths == 0 {
            Storage.numFeedbackBreaths = 10
            Storage.loadTimeFrame = 5
            Storage.updateInterval = 5
        }
        
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    @IBAction func viewPressed(_ sender: UIButton) {
        let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "patientListTableViewController") as! PatientListTableViewController
        viewController.accessType = .view
        self.navigationController?.pushViewController(viewController, animated: true)
    }
    
    @IBAction func enrollPressed(_ sender: UIButton) {
        let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "enrollTableViewController") as! EnrollTableViewController
        self.navigationController?.pushViewController(viewController, animated: true)
    }
    
    
    @IBAction func configPressed(_ sender: UIButton) {
        let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "configurationTableViewController") as! ConfigurationTableViewController
        self.navigationController?.pushViewController(viewController, animated: true)
    }
    
    @IBAction func alertPressed(_ sender: UIButton) {
        let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "patientListTableViewController") as! PatientListTableViewController
        viewController.accessType = .alert
        self.navigationController?.pushViewController(viewController, animated: true)
    }
    
    @IBAction func testFeedbackPressed(_ sender: UIButton) {
        let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "feedbackViewController") as! FeedbackViewController
        viewController.patient = PatientModel(at: 0)!
        self.navigationController?.pushViewController(viewController, animated: true)
    }
    
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

