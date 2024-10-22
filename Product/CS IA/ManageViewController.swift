//
//  ManageViewController.swift

import Foundation
import UIKit

class ManageViewController : UIViewController {
    
    
    @IBOutlet weak var monthCategoryPickerView: UIPickerView!
    
    @IBOutlet weak var receiptsTableView: UITableView!
    
    private var pickerData:[[String]] = [[],["All", "Groceries", "Lifestyle", "Personal & Discretionary", "Transportation", "Miscellaneous"]]
    private var receipts:[[String:Any]] = []
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Setting table view to show the data
        receiptsTableView.delegate = self
        receiptsTableView.dataSource = self
        receiptsTableView.tableFooterView = UIView(frame: CGRect.zero)
        //downloading user dates from database to hold in pickerData. Shown in the pickerview
        FirebaseHandler.downloadUserDates { (downloadedDates) in
            self.pickerData[0] = downloadedDates
            self.monthCategoryPickerView.delegate = self
            self.monthCategoryPickerView.dataSource = self
        }
        
    }
    
    //User wants to see the receipts
    @IBAction func viewReceiptsTapped(_ sender: Any) {
        let dateSelected = pickerData[0][monthCategoryPickerView.selectedRow(inComponent: 0)]
        let categorySelected = pickerData[1][monthCategoryPickerView.selectedRow(inComponent: 1)]
        
        if categorySelected.elementsEqual("All") {
            //Use download all receipts for date
            FirebaseHandler.downloadReceipts(for: dateSelected) { (downloadedReceipts) in
                self.receipts = downloadedReceipts
                self.receiptsTableView.reloadData() //reloading table view
            }
            
        } else {
            //Use download receipts for date & category
            //Check if no receipts
            FirebaseHandler.downloadReceipts(for: dateSelected, in: categorySelected) { (downloadedReceipts) in
                if downloadedReceipts.isEmpty {
                    //Send UI Alert that users have no receipts in this category
                    let alert = UIAlertController(title: "No Receipts", message: "There are no receipts in this category. Choose a different category", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
                    self.present(alert, animated: true)
                    self.receipts = []
                } else {
                    self.receipts = downloadedReceipts
                }
                
                self.receiptsTableView.reloadData()
            }
            
        }
        
    }
    
    
}

extension ManageViewController: UITableViewDataSource, UITableViewDelegate, UIPickerViewDelegate, UIPickerViewDataSource {
    //Conforming to pickerview and tableview protocols
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 2
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        
        if component == 0 {
            return pickerData[0].count
        } else {
            return pickerData[1].count
        }
        
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        
        if component == 0 {
            return pickerData[0][row]
        } else {
            return pickerData[1][row]
        }
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return receipts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let receiptData: [String:Any] = receipts[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "ReceiptsCell") as! ReceiptsCell
        
        cell.setReceipt(receipt: receiptData)
        
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            FirebaseHandler.deleteReceipt(receipts[indexPath.row])
            receipts.remove(at: indexPath.row)
            receiptsTableView.beginUpdates()
            receiptsTableView.deleteRows(at: [indexPath], with: .automatic)
            receiptsTableView.endUpdates()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let destinationDetailViewController = self.storyboard?.instantiateViewController(withIdentifier: "ConfirmReceiptViewController") as! ConfirmReceiptViewController
        
        //Everything from here on happens inside closure from FirebaseHandlerFunction
        //call passData on destinationDetailViewController
        
        FirebaseHandler.getFullReceiptData(fromReceipt: receipts[indexPath.row]) { (receiptData) in
            destinationDetailViewController.passData(withReceipt: receiptData, hasBeenUploaded: true)
            self.navigationController?.pushViewController(destinationDetailViewController, animated: true)
        }
        
        
    }
    

}
