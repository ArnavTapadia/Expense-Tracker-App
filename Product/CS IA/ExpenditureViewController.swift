//
//  ExpenditureViewController.swift

import Foundation
import UIKit

class ExpenditureViewController : UIViewController,UIPickerViewDataSource,UIPickerViewDelegate {
    
    private var pickerMonthsYear:[String] = [""] //Add more months & years from firebase
    //TODO: Should get from firebase class
    
    @IBOutlet weak var monthPickerView: UIPickerView! //Need to have multiple components – month and year
    
    @IBOutlet weak var totalExpenditureLabel: UILabel!
    
    @IBOutlet weak var groceryExpenditureLabel: UILabel!
    
    @IBOutlet weak var lifestyleExpenditureLabel: UILabel!
    
    @IBOutlet weak var personalExpenditureLabel: UILabel!
    
    @IBOutlet weak var transportExpenditureLabel: UILabel!
    
    @IBOutlet weak var miscExpenditureLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        FirebaseHandler.downloadUserDates { (downloadedDates) in
            self.pickerMonthsYear = downloadedDates
            //Setting pickerView data
            self.monthPickerView.delegate = self
            self.monthPickerView.dataSource = self
            self.viewExpenditureTapped(self)
        }
    }
    
    //Downloading expedniture from database
    @IBAction func viewExpenditureTapped(_ sender: Any) {
        FirebaseHandler.getExpenditure(for: pickerMonthsYear[monthPickerView.selectedRow(inComponent: 0)]) { (expenditure) in
            self.totalExpenditureLabel.text = "$" + expenditure["total"]!
            self.groceryExpenditureLabel.text = "$" + expenditure["groceryTotal"]!
            self.lifestyleExpenditureLabel.text = "$" + expenditure["lifestyleTotal"]!
            self.personalExpenditureLabel.text = "$" + expenditure["personalTotal"]!
            self.transportExpenditureLabel.text = "$" + expenditure["transportTotal"]!
            self.miscExpenditureLabel.text = "$" + expenditure["miscellaneousTotal"]!
        }
        
        
    }
    
    //MARK: Conforming to pickerview protocols
    //Month and year --> 2 components
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerMonthsYear.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerMonthsYear[row]
    }
    
}
