//
//  ButtonTableViewCell.swift
//  RealTimeVentView
//
//  Created by user149673 on 2/11/19.
//  Copyright © 2019 CCIL. All rights reserved.
//

import UIKit

protocol ButtonTableViewCellDelegate {
    func submitForm()
}

class ButtonTableViewCell: UITableViewCell {

    var delegate: ButtonTableViewCellDelegate? = nil
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    
    @IBAction func submitPressed(_ sender: UIButton) {
        self.delegate?.submitForm()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
