//
//  LoadingViewController.swift

import Foundation
import UIKit

class ConfirmReceiptViewController : UIViewController{
    
    //MARK: Properties
    
    @IBOutlet weak var dateTextField: UITextField!
    
    @IBOutlet weak var totalTextField: UITextField!
    
    @IBOutlet weak var buyerTextField: UITextField!
    
    @IBOutlet weak var lineItemsView: UITableView!

    @IBOutlet weak var addingItemTextField: UITextField!
    
    @IBOutlet weak var addingPriceTextField: UITextField!
    
    @IBOutlet weak var addingQtyTextField: UITextField!
    
    @IBOutlet weak var categoryPickerView: UIPickerView!
    
    @IBOutlet weak var duplicateReceiptLabel: UILabel!
    
    @IBOutlet weak var verifyReceiptButton: UIButton!
    
    var receipt: Receipt! //Always not-nil
    var lineItems: [[String:Any]]!
    private let categories = ["Miscellaneous", "Groceries", "Lifestyle", "Personal & Discretionary", "Transportation"] //Array of all categories of receipts
    
    var preUploaded = false
    
    //MARK: Actions
    override func viewDidLoad() {
        super.viewDidLoad()
        showData()
        lineItemsView.delegate = self
        lineItemsView.dataSource = self
        lineItemsView.tableFooterView = UIView(frame: CGRect.zero)
        categoryPickerView.delegate = self
        categoryPickerView.dataSource = self
    }
    
    
    func passData(withReceipt createdReceipt: Receipt, hasBeenUploaded uploaded:Bool = false) {
        preUploaded = uploaded
        receipt = createdReceipt
        lineItems = receipt.getLineItems()
    }
    
    private func showData() {
        //setting text field values
        dateTextField.text = receipt.getDate()
        totalTextField.text = "\(receipt.getTotal())"
        buyerTextField.text = receipt.getBuyer()
        
        //If receipt is downloaded from firebase, user should not be able to edit it
        if preUploaded {
            duplicateReceiptLabel.isHidden = true
            verifyReceiptButton.isHidden = true
            
        } else {
            duplicateReceiptLabel.isHidden = !receipt.isDuplicate()
            verifyReceiptButton.isHidden = false
        }
        
    }
    
    //If user edits the OCR data, the receipt object data is updated
    @IBAction func verifyReceiptTapped(_ sender: Any) {
        receipt.setBuyer(as: buyerTextField.text!)
        receipt.setLineItems(to: lineItems)
        receipt.setDate(to: dateTextField.text!)
        receipt.setCategory(to: categories[categoryPickerView.selectedRow(inComponent: 0)])
        receipt.setTotal(to: totalTextField.text!)
        FirebaseHandler.uploadReceipt(thisreceipt: receipt)
        verifyReceiptButton.isHidden = true
        
    }
    
    @IBAction func AddLineItem(_ sender: Any) {
        //Validating that textFields are not empty
        if addingItemTextField.text != "" && Double(addingPriceTextField.text!) != nil && Double(addingQtyTextField.text!) != nil {
            lineItems.append(["desc":addingItemTextField.text!, "lineTotal":addingPriceTextField.text!, "qty":addingQtyTextField.text!]) //Adding item the user wants to add to the receipt
            let indexPath = IndexPath(row: lineItems.count - 1, section: 0)
            lineItemsView.beginUpdates()
            lineItemsView.insertRows(at: [indexPath], with: .automatic)
            lineItemsView.endUpdates()
            //Adding the lineItem to the table view
            
            addingItemTextField.text = ""
            addingPriceTextField.text = ""
            addingQtyTextField.text = ""
            view.endEditing(true)
        } else {
            //UIAlert
            let alert = UIAlertController(title: "Wrong Format", message: "Enter item name, and use only numbers for price and quantity", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
            self.present(alert, animated: true)
        }
    }
    
}

extension ConfirmReceiptViewController: UITableViewDataSource, UITableViewDelegate, UIPickerViewDelegate, UIPickerViewDataSource {
    
    //MARK: UITableView Protocols
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return lineItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let lineItem: [String:Any] = lineItems[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "LineItemsCell") as! LineItemsCell
        cell.setLineItem(lineItem: lineItem)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            lineItems.remove(at: indexPath.row)
            
            lineItemsView.beginUpdates()
            lineItemsView.deleteRows(at: [indexPath], with: .automatic)
            lineItemsView.endUpdates()
        }
    }
    
    //MARK:UIPickerView Protocols
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return categories.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return categories[row]
    }
    
}
