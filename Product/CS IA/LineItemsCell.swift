//
//  LineItemsCell.swift

import UIKit

class LineItemsCell: UITableViewCell {
    
    @IBOutlet weak var itemTextField: UITextField!
    @IBOutlet weak var qtyTextField: UITextField!
    @IBOutlet weak var priceTextField: UITextField!
    
    func setLineItem(lineItem: [String:Any]) {
        //Setting each cells data correctly
        itemTextField.text = (lineItem["desc"] as! String)
        priceTextField.text = "\(lineItem["lineTotal"] ?? "unknown")"
        qtyTextField.text = "\(lineItem["qty"] ?? "unknown")"
    }
    
}
