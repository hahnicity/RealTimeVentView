//
//  SwitchTableViewCell.swift
//  RealTimeVentView
//
//  Created by user149673 on 2/11/19.
//  Copyright © 2019 CCIL. All rights reserved.
//

import UIKit

enum SwitchType {
    case notification, dta, bsa, tvv, notificationAll
}

protocol SwitchTableViewCellDelegate {
    func switchChanged(ofType type: SwitchType, to value: Bool)
}

class SwitchTableViewCell: UITableViewCell {

    @IBOutlet weak var alertSwitch: UISwitch!
    var type: SwitchType = .notification
    var delegate: SwitchTableViewCellDelegate? = nil
    
    override func awakeFromNib() {
        super.awakeFromNib()        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @IBAction func switchChanged(_ sender: UISwitch) {
        delegate?.switchChanged(ofType: type, to: sender.isOn)
    }
    
    

}
