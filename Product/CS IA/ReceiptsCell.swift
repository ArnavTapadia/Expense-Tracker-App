//
//  ReceiptsCell.swift

import UIKit
import Foundation


class ReceiptsCell: UITableViewCell {
    
    @IBOutlet weak var categoryLabel: UILabel!
    
    @IBOutlet weak var totalLabel: UILabel!
    
    @IBOutlet weak var buyerLabelValue: UILabel!
    
    @IBOutlet weak var dateLabel: UILabel!
    
    @IBOutlet weak var totalLabelValue: UILabel!
    
    @IBOutlet weak var buyerLabel: UILabel!
    
    @IBOutlet weak var dateLabelValue: UILabel!
    
    func setReceipt(receipt:[String:Any]) {
        //setting data for each cell
        let shortData = receipt[Array(receipt.keys)[0]] as? [String:String]
        buyerLabelValue.text! = shortData!["buyer"]!
        totalLabelValue.text! = "$" + shortData!["total"]!
        dateLabelValue.text! = shortData!["date"]!
        categoryLabel.text! = shortData!["category"]!
    }
    
    
}
