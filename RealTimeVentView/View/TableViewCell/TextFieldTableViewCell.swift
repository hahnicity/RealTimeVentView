//
//  TextFieldTableViewCell.swift
//  RealTimeVentView
//
//  Created by user149673 on 2/10/19.
//  Copyright © 2019 CCIL. All rights reserved.
//

import UIKit

enum TextFieldType {
    case loadTimeFrame, updateInterval, numFeedbackBreaths, thresholdDTA, thresholdBSA, thresholdTVV
}

protocol TextFieldTableViewCellDelegate {
    func editingText(_ text: String)
    func textChanged(ofType type: TextFieldType, to value: String)
}

class TextFieldTableViewCell: UITableViewCell, UITextFieldDelegate {

    @IBOutlet weak var textField: UITextField!
    var suggestion = ""
    var delegate: TextFieldTableViewCellDelegate? = nil
    var type: TextFieldType = .loadTimeFrame
    
    override func awakeFromNib() {
        super.awakeFromNib()
        textField.delegate = self
        // Initialization code
    }
    
    @IBAction func textChanged(_ sender: UITextField) {
        delegate?.editingText(sender.text ?? "")
        delegate?.textChanged(ofType: type, to: sender.text ?? "")
    }
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.endEditing(true)
        return false
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
