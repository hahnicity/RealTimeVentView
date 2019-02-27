//
//  PickerTableViewCell.swift
//  RealTimeVentView
//
//  Created by user149673 on 2/11/19.
//  Copyright © 2019 CCIL. All rights reserved.
//

import UIKit

protocol PickerTableViewCellDelegate {
    func selectSex(atIndex index: Int)
}

class PickerTableViewCell: UITableViewCell, UIPickerViewDelegate, UIPickerViewDataSource {

    @IBOutlet weak var picker: UIPickerView!
    
    let sex = ["Male", "Female"]
    var index: Int = 0
    var delegate: PickerTableViewCellDelegate? = nil
    
    override func awakeFromNib() {
        super.awakeFromNib()
        picker.delegate = self
        picker.dataSource = self
        // Initialization code
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return sex.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return sex[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        index = row
        delegate?.selectSex(atIndex: index)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
