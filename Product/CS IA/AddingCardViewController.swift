//
//  AddingCardViewController.swift
//  CS IA
//
//  Created by Arnav Tapadia on 12/6/19.
//  Copyright © 2019 Arnav Tapadia. All rights reserved.
//

//TODO: Delete

import Foundation
import UIKit

class AddingCardViewController : UIViewController {
    
   
    @IBOutlet weak var expiryDateTextField: UITextField!
    private var datePicker: UIDatePicker?
    
    @IBOutlet weak var cardNoField: UITextField!
    
    @IBOutlet weak var cvvField: UITextField!
    
    @IBOutlet weak var cardNameField: UITextField!
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        datePicker = UIDatePicker()
        datePicker?.datePickerMode = .date
        datePicker?.addTarget(self, action: #selector(AddingCardViewController.dateChanged(datePicker:)), for: .valueChanged)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(AddingCardViewController.viewTapped(gestureRecognizer:)))
        view.addGestureRecognizer(tapGesture)
        
        expiryDateTextField.inputView = datePicker
    }
    
    @IBAction func addCardTapped(_ sender: Any) {
        //Save data to database
    }
    
    @objc func viewTapped(gestureRecognizer: UITapGestureRecognizer) {
        view.endEditing(true)
    }
    
    @objc func dateChanged(datePicker: UIDatePicker) {
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"
        
        expiryDateTextField.text = dateFormatter.string(from: datePicker.date)
        
    }
    
}
